---
title: Migration 42 : colonnes divine_energy_cost (sorts, recettes, cases)
slug: divine-energy-cost-schema
status: done
updated: 2026-11-26
files:
  - db/42_energie_divine_couts.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Ajoute le coût en énergie divine, à côté du coût en énergie, aux sorts, recettes de parchemin et types de case.

## Business rules
- `spells`, `recipes`, `tile_types` : `divine_energy_cost INT NOT NULL DEFAULT 0 CHECK (>= 0)` ; idempotent (`ADD COLUMN IF NOT EXISTS`).
- Le passage de rang n'a pas de colonne : `divineEnergyCost` vit dans le JSON `specializations.requirements`.

## Gotchas
- Défaut 0 obligatoire : les lignes existantes ne doivent rien exiger.

## Tests
`scripts/check-sql.sh` (syntaxe) ; règles couvertes par `back/test/integration/divineCost.test.ts`.
