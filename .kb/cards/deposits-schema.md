---
title: Migration 23 : gisements de ressources
slug: deposits-schema
status: done
updated: 2026-11-24
files:
  - db/23_gisements.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 23 : table des gisements de ressources.

## Business rules
- `resource_deposits` : monde (supprimé avec la carte), zone `x_min..x_max × y_min..y_max` (max ≥ min), ressource (id du catalogue), `stock` ≥ 0, `stock_max` ≥ 1, `regen_per_h` ≥ 0, `yield_per_harvest` ≥ 1, `active`.
- Index par monde.
- Idempotente.

## Gotchas
- La ressource n'a pas de clé étrangère (catalogue en code) : vérifiée par l'API.

## Tests
`scripts/check-sql.sh` ; back `deposits.test.ts`.
