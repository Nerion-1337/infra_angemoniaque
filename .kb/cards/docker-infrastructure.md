---
title: Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations
slug: docker-infrastructure
status: done
updated: 2026-10-20
files:
  - docker-compose.yml
  - docker-compose.dev.yml
  - docker-compose.prod.yml
  - nginx/nginx.conf
  - nginx/nginx.dev.conf
  - db/01_init.sql
  - db/02_extra.sql
  - db/03_features.sql
  - db/04_guild_order.sql
  - db/05_rank_order.sql
  - db/06_default_rank.sql
  - db/07_forum_perms.sql
  - scripts/check-sql.sh
  - scripts/backup-db.sh
  - Makefile
  - .env.example
symbols:
  - docker-compose.dev.yml:angemoniaque-dev
  - docker-compose.prod.yml:angemoniaque-prod
  - nginx/nginx.conf:proxy_pass
  - nginx/nginx.dev.conf:proxy_pass
  - db/01_init.sql:game_schema
  - db/02_extra.sql:accounts
  - db/03_features.sql:summons
  - db/04_guild_order.sql:sort_order
  - db/05_rank_order.sql:sort_order
  - db/06_default_rank.sql:default_rank_id
  - db/07_forum_perms.sql:write_ranks
  - scripts/check-sql.sh:ON_ERROR_STOP
  - scripts/backup-db.sh:pg_dump
  - Makefile:dev-up
tests:
  - scripts/check-sql.sh
---
## Purpose
Orchestrates the whole project on Docker: three compose targets (base, dev, prod) defining Postgres 16, Redis 7, the backend and frontend containers, an Nginx reverse proxy and ops tools (PgAdmin, Portainer in prod). It also owns the ordered SQL migrations that build the `game_schema` schema consumed by the backend, plus ops scripts (SQL validation, database backup).

## How it works
- `.env` (created from `.env.example` by `make init`) provides POSTGRES_USER/POSTGRES_PASSWORD/POSTGRES_DB, JWT_SECRET and PgAdmin credentials. All three compose files use `env_file: .env`.
- `docker-compose.yml` (base) declares the service graph: postgres (healthcheck `pg_isready`, data in volume `pgdata`, migrations mounted read-only at `/docker-entrypoint-initdb.d`), redis (healthcheck `redis-cli ping`), backend (built from `${BACKEND_PATH:-../backend}`, gets `DATABASE_URL`/`REDIS_URL`, waits for healthy postgres+redis), frontend (built from `${FRONTEND_PATH:-../frontend}`) and nginx:1.27 on port 80.
- `docker-compose.dev.yml` overlays project `angemoniaque-dev` (containers `ange-dev-*`): separate volumes `pgdata_dev` + named `*_modules_dev` volumes for node_modules, exposed ports 8080 (game) / 5433 (postgres) / 5051 (PgAdmin); sources are bind-mounted and node_modules stay in named volumes so the host never sees dependencies; backend runs the Dockerfile `dev` target (`npm run dev`, hot reload with `CHOKIDAR_USEPOLLING`), frontend the Vite dev server on 5173.
- `docker-compose.prod.yml` overlays project `angemoniaque-prod` (containers `ange-prod-*`): single `pgdata` volume, `:prod` image targets, nginx serves the static frontend build and proxies the API on port 80, plus PgAdmin (:5050) and Portainer (:9000).
- `nginx/nginx.conf` (prod): `/api/` → `http://backend:3000/` (prefix stripped) with WebSocket upgrade headers; `/` → `http://frontend:80` (static dist). `nginx/nginx.dev.conf` is identical except `/` → `http://frontend:5173` (Vite HMR).
- Migrations run in lexicographic order on first start of an empty volume: `01_init.sql` creates `game_schema` (maps, specializations, stat_cost_rules, characters, …), `02_extra.sql` adds accounts/guilds/guild forum and item/mount columns, `03_features.sql` adds summons, controlled summons and spells, `04_guild_order.sql` adds `sort_order` to the guild forum tables (category/topic reordering, back `POST /guilds/reorder`), `05_rank_order.sql` adds `sort_order` to `guild_ranks` (rank-card reordering in the manage tab, back `POST /guilds/reorder` with `kind: 'ranks'`), `06_default_rank.sql` adds `default_rank_id` to `guilds` (default rank for newcomers, back `POST /guilds/default-rank`), `07_forum_perms.sql` adds `description` + `write_ranks` to `guild_folders`/`guild_topics` and the `guild_topic_reads` table (granular read/write forum perms + unread tracking, back card `guild-forum-perms`).
- `scripts/check-sql.sh` re-applies `db/*.sql` in order on a fresh database with `ON_ERROR_STOP=1` and smoke-selects `game_schema.specializations`; `scripts/backup-db.sh [dev|prod]` pg_dumps the running postgres container to a timestamped SQL file.
- `Makefile` is the single entry point: `dev-up/dev-down/dev-reset/dev-logs/dev-deps`, `test-back/test-front` (build the Dockerfile `test` target), `test-int` (integration tests inside the dev stack), `prod-up/prod-down/prod-logs`.

## Entry points
- `make dev-up` / `make prod-up` (Makefile) — the only intended ways to start either stack
- `.github/workflows/ci.yml` — validates both compose files (`config -q`), runs `check-sql.sh` against a postgres service, and `nginx -t` on `nginx/nginx.conf`
- `.github/workflows/cd.yml` — deploys on `v*` tags (git pull + compose up on the host)
- `front/Dockerfile` + `back/Dockerfile` — build contexts referenced by the compose files (`build: context: ${BACKEND_PATH:-../backend}`)

## Data flow
- Browser → Nginx :80 (prod) / :8080 (dev): `/` → frontend (static in prod, Vite:5173 in dev); `/api/...` → backend:3000 with the `/api` prefix stripped and WS upgrade headers forwarded
- backend → Postgres via `DATABASE_URL` (connection string built by compose; pool options force `search_path=game_schema`)
- backend → Redis via `REDIS_URL` for realtime pub/sub (`map:{id}` channels, see `back` repo `realtime/ws.ts`)
- Persistence: `pgdata` / `pgdata_dev` volumes for Postgres; `portainer` volume; node_modules live in `backend_modules_dev` / `frontend_modules_dev` (dev only, never on the host)

## Tests
- `scripts/check-sql.sh` — applies all migrations to a pristine database (fresh `angemoniaque` DB via psql, `ON_ERROR_STOP=1`) and checks the `specializations` table exists; run in CI with a postgres service and locally when psql is available. Also registered via `kb init --test-cmd` for the local (docker-less) validation used by `kb finish`.
- Compose syntax: `docker compose -f docker-compose.dev.yml config -q` and same for prod (CI step).
- Nginx syntax: `nginx -t` against `nginx/nginx.conf` (CI step).

## Gotchas
- Migrations only run when the Postgres data volume is empty: any schema change in `db/` requires `make dev-reset` (drops `pgdata_dev`) in dev; prod needs a manual migration path — adding a file does NOT alter existing volumes.
- `db/*.sql` must stay in lexicographic order; `02_extra.sql`, `03_features.sql`, `04_guild_order.sql`, `05_rank_order.sql` and `06_default_rank.sql` ALTER tables created by `01_init.sql` — renumbering or reordering breaks a fresh init.
- `BACKEND_PATH` / `FRONTEND_PATH` (default `../backend`, `../frontend`) assume the repos are checked out side-by-side; relocate and export the variables.
- Dev and prod run in parallel by design (separate compose projects, ports and volumes) — do not reuse dev ports in prod or vice versa.
- Absolute rule: this repo must never modify `../front` or `../back`; if an app-side change is needed to adapt to the infra, document it and report it instead.
- `JWT_SECRET`, `PGADMIN_*` and Postgres credentials come from `.env` (gitignored secret); `.env.example` holds the dev defaults (`ange`/`change-me`) — prod credentials must differ.
- Nginx here terminates plaintext HTTP; SSL/TLS termination in production is an operator-level concern (documented in AGENTS.md).
- `portainer` mounts `/var/run/docker.sock` — prod-only, do not add it to dev.
