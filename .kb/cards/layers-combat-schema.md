---
title: Migration 46 : couche air des positions, arme à distance, XP de combat / entraînement, XP au coup des monstres
slug: layers-combat-schema
status: done
updated: 2026-11-27
files:
  - db/46_couches_portee_xp.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma du lot du 2026-11-27 : deux entités par case (une au sol, une dans les airs), arme à distance, XP de combat et d entraînement par rang, XP au coup par type de monstre.

## Business rules
- `positions.air` (BOOLEAN) calculé par `trg_pos_air` (BEFORE INSERT/UPDATE, `pos_air_of`) ; recalcul sur changement de `characters.riding_summon_id` et de `monsters.locomotion` ; `uq_cell` = (map_id, x, y, air) hors objets et bâtiments.
- `items.ranged`, `specializations.xp_hit_player / xp_dodge / train_energy / train_xp`, `monsters.xp_hit` : entiers ≥ 0 (défaut 0 / faux). Idempotente.

## Gotchas
- L'ancien `uq_cell` est supprimé AVANT le calcul initial de `air` puis recréé.

## Tests
`scripts/check-sql.sh` (syntaxe) ; règles couvertes par `back/test/integration/layersCombat.test.ts`.
