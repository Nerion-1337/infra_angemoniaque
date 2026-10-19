# Project overview
_Généré par `kb overview` — ne pas éditer ici ; notes manuelles dans `.kb/NOTES.md`._

# Project notes (maintenus à la main / par l'agent)

## Stack & conventions
- Docker Compose 3 fichiers : base, `dev` (projet `angemoniaque-dev`, ports 8080/5433/5051, sources bind-mountées, node_modules en volumes nommés), `prod` (projet `angemoniaque-prod`, ports 80/5050/9000)
- Nginx : `/` → front (dist statique en prod, Vite:5173 en dev), `/api/` → back:3000 (prefix stripé, upgrade WS)
- Migrations `db/*.sql` en ordre lexicographique, appliquées uniquement sur volume vide ; changements de schéma = `make dev-reset` (dev)
- Règle absolue : ne JAMAIS modifier `../front` ou `../back` depuis ce dépôt — documenter et signaler
- Secrets dans `.env` (jamais commité) ; `.env.example` = template

## Commandes utiles
- dev : `make dev-up` (jeu sur http://localhost:8080) ; prod : `make prod-up` (http://localhost)
- validation locale (sans docker/psql) : `bash -n scripts/*.sh` + parsing YAML des 3 compose (`kb` test_cmd)
- tests SQL (psql requis) : `scripts/check-sql.sh` ; backup : `scripts/backup-db.sh [dev|prod]`
- kb : backend d'embedding `hash` (offline) dans `.kb/config.json`

## Features (1)
- **docker-infrastructure** [done] (.kb/cards/docker-infrastructure.md) Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations — Orchestrates the whole project on Docker: three compose targets (base, dev, prod) defining Postgres 16, Redis 7, the backend and frontend containers, an Nginx reverse proxy and ops tools (PgAdmin, Por — files: docker-compose.yml, docker-compose.dev.yml, docker-compose.prod.yml, nginx/nginx.conf (+8)

## File map
- `db/01_init.sql`
- `db/02_extra.sql`
- `db/03_features.sql`
- `docker-compose.dev.yml` — DEV — projet "angemoniaque-dev" : conteneurs ange-dev-*, base/volumes/réseau séparés de la prod, ports différe
- `docker-compose.prod.yml` — PROD — projet "angemoniaque-prod" : conteneurs ange-prod-*, volumes et réseau propres, images :prod
- `docker-compose.yml` — Dépôt infra : orchestre TOUT (db, cache, back, front, proxy, outils). Les dépôts backend/ et frontend/ sont cl
- `scripts/backup-db.sh` — Sauvegarde SQL (reprise du dépôt d'origine). Usage : ./backup-db.sh [dev|prod]
- `scripts/check-sql.sh` — Applique les scripts SQL dans l'ordre sur une base vierge (CI + pre-commit si psql dispo).
