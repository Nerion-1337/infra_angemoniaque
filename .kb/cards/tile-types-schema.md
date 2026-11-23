---
title: Table tile_types (migration 15) : types de case par monde
slug: tile-types-schema
status: done
updated: 2026-11-23
files:
  - db/15_types_de_case.sql
symbols:
tests:
  - scripts/check-sql.sh
---
## Purpose
Table `game_schema.tile_types` : un type de case par (monde, kind) avec nom, description, coût d'énergie et sort passif optionnel,
éditée par la section admin « Cases » (cards `back/tile-types`, `front/admin-tiles-ui`).

## How it works
`db/15_types_de_case.sql` : `CREATE TABLE IF NOT EXISTS tile_types(map_id → maps ON DELETE CASCADE, kind CHECK 9 valeurs, name, description,
energy_cost CHECK 0..99, spell_id → spells ON DELETE SET NULL, spell_mode CHECK bonus|malus, PK(map_id, kind))` puis seed `INSERT … ON CONFLICT DO NOTHING`
avec les valeurs du code (`KIND_COST`/`KIND_LABEL`) : 9 types pour les mondes 1 et 2, 5 pour le monde 3 (plain/forest/mountain/shallow/deep).

## Entry points
Appliquée par l'entrypoint Postgres sur volume neuf, ou par le `migrator` (`scripts/migrate.sh`, pas de marqueur : fichier nouveau = appliqué s'il manque) ; la CI back rejoue `db/*.sql`.

## Data flow
Lue par le back (`game/tileTypes.ts`, cache 30 s) ; écrite par `PUT /admin/content/tiles/{mapId}/{kind}`.

## Tests
Rejouée deux fois sur la stack (entrypoint puis migrator : NOTICE « already exists », OK). Couverte par `back/test/integration/tiles.test.ts`.

## Gotchas
- Idempotente : ne jamais transformer le seed en UPDATE (écraserait les réglages admin).
- Un nouveau `kind` de terrain exige d'élargir le CHECK et d'ajouter les lignes seed par monde, en plus du code (`terrain.ts`, `world2.ts`).

