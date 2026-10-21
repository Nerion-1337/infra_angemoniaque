---
title: World schema: maps, positions (entity placement), character resources JSONB
slug: world-schema
status: done
updated: 2026-10-21
files:
  - db/01_init.sql
  - db/02_extra.sql
symbols:
  - db/01_init.sql:maps
  - db/01_init.sql:positions
  - db/01_init.sql:chk_char_limit
  - db/02_extra.sql:resources
tests:
  - scripts/check-sql.sh
---
## Purpose
The static world of the game in Postgres (`game_schema`): the three maps (dimensions only — the terrain itself is procedural, computed by `back/src/game/terrain.ts`, nothing per-cell is stored), the single `positions` table that places EVERY entity (character, monster, summon, building, mount, dropped item) on a map cell, the per-character `resources` JSONB (harvested `perle/eau/herbe/bois/pierre`), the invulnerable buildings (capitals + inter-world doors), and the population limits that keep the world bounded.

## How it works
- `maps` (01_init): `id, name_file, width, height` with 3 rows — `humains.map` 200×200, `anges_demons.map` 200×200, `morts.map` 100×100. Only dimensions + name: the cell content (kind/cost/resource) is a pure function of coordinates (back card `map-terrain-gather`), so maps never need per-cell rows. Map 3 (morts) is the dead-heroes parking lot (back `die()` repositions there).
- `positions` (01_init): one table, polymorphic rows — exactly one of `character_id/monsters_id/building_id/mount_id/item_id` is set (`chk_exclusive_entity` via `num_nonnulls(…)=1`), 01_init `UNIQUE uq_pos_char` on `character_id` (one spot per character), and 02_extra `UNIQUE uq_cell ON positions(map_id,coord_x,coord_y) WHERE item_id IS NULL` → **the database itself guarantees one entity per cell** (dropped items are exempt: many items can share a cell). This is why back never has a race on cell occupancy: a duplicate insert dies with PG `23505`, translated to `409 'Déjà existant ou case occupée'` in `app.onError`.
- `characters.resources` JSONB `DEFAULT '{}'` (02_extra): the harvest ledger `{herbe: 3, bois: 1, …}` updated by `jsonb_set(…)+1` on `/actions/gather` (back card `map-terrain-gather`); read back by `GET /inventory/{characterId}`. It is a plain JSONB bag — no schema inside, keys = resource names, values = counts.
- Seeded static world (02_extra): 6 invulnerable buildings — 3 capitals (`Hôtel de ville` map 1 @100,100; `Bastion Infernal` + `Sanctuaire de la Providence` map 2) and 3 doors linking the worlds (`Le Seuil des Deux Voiles` map 1 → map 2 @12,10 needs an `artefact`; `Brèche de Soufre` map 2 → map 1 @12,10 needs `arcane`; `L'Arche de Grâce` map 2 → map 1 @22,10 needs `relique` — `data.requires` = the divine-item kind, `data.to = [map,x,y]`), the 3 world-guarding monsters placed (`Léviathan` map 2 @50,50, `Balrog` map 2 @150,150, `Minotaure` map 1 @150,60), and `divine_items` (4 reliques + 4 arcane + 5 artefacts, each `guardian_monster_id` — monsters drop them on kill, doors consume them via `POST /divine/door`).
- `chk_char_limit` trigger (01_init): BEFORE INSERT on `characters` — max **3 characters per account, same race** (`RAISE EXCEPTION '3 personnages max' / 'Même race obligatoire'` → back maps PG `P0001` to `400`).

## Entry points
- Postgres entrypoint applies `db/*.sql` in lexicographic order on an **empty** volume only (infra card `docker-infrastructure`) — `01_init` then `02_extra`; renumbering or reordering breaks a fresh init (`02_extra` ALTERs `01_init` tables).
- All world writes go through back (`positions` in `movement.travel` / `spawn.freeCell` / combat deaths; `resources` in `actions.gather`); the infra repo only ships the schema + seeds. The back integration tests (`back/test/integration/map-gather.test.ts` etc.) are the de-facto tests of this schema, run against a freshly-initiated Postgres.

## Data flow
Reads/writes live in `game_schema` (`search_path=game_schema` set by the back pool — every query is unqualified). Entity placement: `positions` row ↔ exactly one entity; a character's row moves on every successful travel. Harvests: `characters.resources` JSONB += 1. Doors: `buildings.data` JSON (`requires`/`to`) consumed by `routes/divine.ts`; `divine_items` holder moves to the killer (`holder_character_id`) and back to the guarded state on door use. No triggers on `positions` (occupancy is purely the `uq_cell` unique index), no FKs from `positions` to `summons` (summoned placements use their own `summon_id` column added in `03_features`).

## Tests
No SQL test suite in infra (the registered `test_cmd` only syntax-validates scripts + compose files). Coverage of this schema: `back/test/integration/map-gather.test.ts` (map bounds 409, in-place/ranged gather → `resources`, deep-water 409, zone privacy), `back/test/integration/api.test.ts` (spawn + `chk_char_limit` same-race 400), and the guild/combat suites (positions churn). Run them with a fresh Postgres (`make test-int` after `dev-up`, or `stack up`).

## Gotchas
- **Fresh-volume-only init**: migrations run once on an empty `pgdata` volume; an existing volume is never migrated — schema changes need a reset (`dev-reset` / `stack down && stack up` deletes the volume).
- `uq_cell` is a partial unique index (`WHERE item_id IS NULL`): dropped items can stack in one cell, entities cannot. Any new entity kind added to `positions` must respect the `num_nonnulls=1` check.
- `maps` stores only dimensions: the map *content* (terrain/resources) is deterministic noise in back+front — changing thresholds in `terrain.ts` changes every map at once (mirror in `front/src/lib/terrain.js`, back card `map-terrain-gather`).
- The seed coordinates are load-bearing: capitals are the spawn rings' centers (`spawn.freeCell`, r=4) and the 37-cell walkable ring of map 1 saturates in a long-lived dev DB (back `freeCell` now widens the radius rather than failing 503).
- `resources` JSONB is unstructured: nothing stops a key other than the 5 resource names from appearing — always `jsonb_set` with the terrain resource, never free-text keys.
