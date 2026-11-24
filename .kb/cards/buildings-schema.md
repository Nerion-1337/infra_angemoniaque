---
title: Migration 22 : bâtiments paramétrables et unicité des cases séparée
slug: buildings-schema
status: done
updated: 2026-11-24
files:
  - db/22_batiments.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 22 : colonnes des bâtiments paramétrables et séparation de l'unicité des cases (entités / bâtiments).

## Business rules
- `buildings` : `armor` (≥ 0), `occupiable` (défaut faux), `occupant_attack` JSONB (défaut tout permis), `bonus_armor`, `bonus_see`, `bonus_range`.
- `uq_cell` : une entité au plus par case (hors objets au sol et bâtiments) ; `uq_cell_building` : un bâtiment au plus par case.
- Idempotente (l'index `uq_cell` est supprimé puis recréé).

## Gotchas
- Un bâtiment non occupable ne bloque plus sa case PAR LA BASE : c'est le code (`BLOCKING`, contrôles de placement) qui l'en empêche.

## Tests
`scripts/check-sql.sh` ; back `buildings.test.ts`.
