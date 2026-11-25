---
title: Migrations 23, 30, 31 : secteurs de ressources, leurs ressources, conditions de récolte
slug: deposits-schema
status: done
updated: 2026-11-25
files:
  - db/23_gisements.sql
  - db/30_secteurs_ressources.sql
  - db/31_conditions_recolte.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migrations 23 et 30 : secteurs de ressources (zone d'un monde) et leurs ressources.

## Business rules
- `resource_deposits` (secteur) : monde (supprimé avec la carte), zone `x_min..x_max × y_min..y_max` (max ≥ min), `name`, `active` ; index par monde.
- `deposit_resources` : secteur (CASCADE), ressource (id du catalogue, unique par secteur), `percent` 1–100, `kind` (type de case ou NULL = toute case), `stock` ≥ 0, `stock_max` ≥ 1, `regen_per_h` ≥ 0, `yield_per_harvest` ≥ 1.
- Migration 30 : chaque ancien gisement devient un secteur à une ressource (100 %, toute case) ; les anciennes colonnes de stock sont supprimées ensuite.
- Somme des parts ≤ 100 % par type de case : vérifiée par l'API, pas par la base.
- Idempotentes (reprise gardée par la présence de l'ancienne colonne `resource`).
- Migration 31 : `resource_rules(resource PK, harvest JSONB {groups})` — conditions de récolte par ressource du catalogue (format des conditions d'activation des bâtiments) ; sans ligne = récolte libre.

## Gotchas
- La ressource n'a pas de clé étrangère (catalogue en code) : vérifiée par l'API.

## Tests
`scripts/check-sql.sh` ; reprise 23 → 30 vérifiée sur une base jetable (appliquée deux fois) ; back `deposits.test.ts`.
