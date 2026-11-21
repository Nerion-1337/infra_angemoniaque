---
title: World schema: maps, positions (entity placement), character resources JSONB
slug: world-schema
status: done
updated: 2026-11-21
files:
  - db/01_init.sql
  - db/02_extra.sql
  - db/08_world.sql
symbols:
  - db/01_init.sql:maps
  - db/01_init.sql:positions
  - db/01_init.sql:chk_char_limit
  - db/02_extra.sql:resources
tests:
  - scripts/check-sql.sh
---
## Purpose
The PostgreSQL baseline: `db/01_init.sql` (schema + seed data) and `db/02_extra.sql` (extra columns/features), plus the feature migrations that follow it (guild order, ranks, forum, world v2). All of it is read by the back (`back/src/routes/*`), and its **order and idempotency** are part of the contract.

## How it works
- `01_init.sql`: schema `game_schema` (`search_path` set per connection), the core tables (`users`, `characters`, `accounts`, `characters.resources` JSONB…), the `positions` table (one row per occupied cell, `item_id` distinguishes entities), `maps` (200×200, world 1 = Humans with the safe zone), the `checks` that gate races/summons, the `chk_char_limit` (3 characters per account, same race) and the seed data (races, items, a first village with a portal).
- `02_extra.sql`: adds `characters.resources` JSONB, the `capitals` and `doors` building kinds, the `buildings` seed (a portal + a door per world), and the `monsters` table with its spawn points.
- Feature migrations follow numerically (`03_features.sql`, `04_guild_order.sql`, `05_rank_order.sql`, `06_default_rank.sql`, `07_forum_perms.sql`, `08_world.sql`, …). The files are **lexicographic**: a new `04_*.sql` migration lands **after** `03_features.sql` but **before** the forum `07` — check the sort order before naming a new file. Note: files are **not** all idempotent; they are each applied exactly once (fresh volume via the entrypoint, existing volume via the `migrator` service / `scripts/migrate.sh`, tracked in `game_schema.schema_migrations` — card `schema-migrations-catchup`).
- `08_world.sql` (world v2): `characters.burn_until` (volcano burn, hourly tick of `BURN_DAMAGE`), the 4 portals of the Human world (all `kind='artefact'`, `Le Seuil des Deux Voiles`/`Portail de Givre`/`Porte des Dunes`/`Passage des Marais`, coordinates in sync with `FEATURES` of the back `humanMap`), the return portal moved into the safe zone (next to the town hall), and the Minotaure tree relocated to (146, 68).

## Entry points
- Postgres: on a **fresh** volume every `db` container applies `db/0*.sql` in lexicographic order at first boot; on an **existing** volume the `migrator` service (`scripts/migrate.sh`) catches up the missing files. The back connects with `search_path=game_schema`.
- The back's `routes/*` assumes the columns from `02_extra.sql` (e.g. `characters.resources`), and `game/burn.ts` + `routes/tick.ts` assume `08_world.sql` (`burn_until`).

## Data flow
Reads: the back `db` pool (single source of truth for characters, positions, buildings); the infra also owns the nginx front/back proxies and the Redis config — but the **schema is here**. Writes: migrations are applied by the Postgres entrypoint (fresh volume) and the `migrator` service (existing volume); the back itself writes into the game tables but never into `db/`.

## Tests
- No unit test in this repo; the CI `test` job runs `npm test` (a syntax check of the SQL files).
- The real integration proof is the back's `test/integration/map-gather.test.ts` (run with `stack exec backend`): it exercises `positions`, `characters.resources` and the safe zone end-to-end; a fresh `stack up` applies the `08_world.sql` migration on the new DB (the `burn_until` column appears).

- **Migration 14 (phase 4, rareté & acquisition)** : `items.usable_by` (jsonb, 6 kinds —
  qui peut s'en équiper) ; `spells.rarity` (CHECK 5 valeurs) + `spells.usable_by` (jsonb —
  qui peut l'apprendre). `items.rarity` reste du texte libre (données historiques « Épique »,
  « unique »…) : la normalisation se fait côté API admin (`rarity_n`), pas par contrainte.

## Gotchas
- File order: `db/0*.sql` are applied **in lexicographic order** — `04_world.sql` (later `08_world.sql`) comes **after** `03_features.sql` and **before** the forum `07_*.sql` files: the forum permissions would otherwise see the **pre**-`04` schema. Renaming a migration is only safe on a fresh DB; on a shared dev DB the already-applied file keeps its old name.
- Migrations are applied **once per file** (fresh via entrypoint, existing via the `migrator`), not by re-running them: most `db/*.sql` are **not** idempotent. Do not rely on `IF NOT EXISTS` to make a migration re-runnable; a half-applied file must be finished by hand and recorded in `game_schema.schema_migrations` (see card `schema-migrations-catchup`).
- `positions` is the single source of truth for "who is on which cell" — the back never recomputes it from `characters` alone; a stray `DELETE` would orphan entities (see the back card `map-terrain-gather`).
- `08_world.sql` coordinates (portals, safe zone, Minotaure) are **copied** from the back's generated `humanMap.ts` `FEATURES` — keep them in sync when the map is re-generated.
