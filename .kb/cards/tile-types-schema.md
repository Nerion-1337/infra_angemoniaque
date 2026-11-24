---
title: Table tile_types (migration 15) : types de case par monde
slug: tile-types-schema
status: done
updated: 2026-11-24
files:
  - db/15_types_de_case.sql
symbols:
tests:
  - scripts/check-sql.sh
---
## Purpose
Table `tile_types` (migration 15) : un type de case par (monde, kind) avec nom, description, coût d'énergie et sort passif,
éditée par la section admin « Cases ».

## Business rules
- Clé (map_id, kind) ; kind ∈ 9 valeurs (CHECK) ; coût 0..99 ; `spell_mode` ∈ {bonus, malus}.
- Supprimer une carte supprime ses types ; supprimer un sort met `spell_id` à NULL.
- Reprise : valeurs actuelles du code, 9 types pour les mondes 1 et 2, 5 pour le monde 3 ; aucun changement de jeu à l'application.
- Idempotente (IF NOT EXISTS, ON CONFLICT DO NOTHING).

## Gotchas
- Ne jamais transformer la reprise en UPDATE (écraserait les réglages admin).
- Un nouveau kind exige d'élargir le CHECK, d'ajouter les lignes par monde et de modifier le code (`terrain.ts`, `world2.ts`).

## Tests
`scripts/check-sql.sh` ; rejouée deux fois sur la stack ; back `test/integration/tiles.test.ts`.
