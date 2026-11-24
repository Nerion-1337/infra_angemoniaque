---
title: World schema: maps, positions (entity placement), character resources JSONB
slug: world-schema
status: done
updated: 2026-11-24
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
Socle du schéma PostgreSQL (`01_init.sql`, `02_extra.sql`) et migrations de fonctionnalités qui suivent (guildes, forum, monde v2,
admin, bestiaire, rareté…), lus par le back ; leur ordre fait partie du contrat.

## Business rules
- Tout vit dans le schéma `game_schema` (le back impose `search_path`).
- `positions` est la seule source de vérité de « qui est sur quelle case » (une ligne par case occupée ; `item_id` distingue les objets au sol).
- Ordre lexicographique des fichiers ; la plupart ne sont PAS idempotents (appliqués une fois par fichier).
- `08_world.sql` : `characters.burn_until` (brûlure du volcan) et 4 portails du Monde des Hommes, coordonnées copiées de `FEATURES` du back.
- `14_rarete_acquisition.sql` : `items.usable_by`, `spells.rarity` (CHECK 5 valeurs), `spells.usable_by` ; `items.rarity` reste du texte libre (normalisé par l'API).
- Le trigger de création de personnage `chk_char_limit` (01) a été réécrit par la migration 17 (card `races-clock-schema`).

## Gotchas
- Renommer une migration n'est sûr que sur une base neuve.
- Ne pas compter sur `IF NOT EXISTS` pour rendre rejouable une ancienne migration.
- Régénérer la carte du back impose de resynchroniser les coordonnées de `08_world.sql`.

## Tests
`scripts/check-sql.sh` ; preuve d'intégration côté back (`map-gather.test.ts` sur la stack).
