---
title: Migration 19 : boutique par race et recettes de parchemins
slug: recipes-shop-schema
status: done
updated: 2026-11-24
files:
  - db/19_boutique_parchemins.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 19 : boutique de l'hôtel de ville par race (objets, sorts) et table des recettes de parchemins.

## Business rules
- `items.shop_races`, `spells.shop_races` : JSONB, [] = toutes les races ; `spells.shop` (défaut TRUE : les sorts restent en boutique).
- `recipes` : un parchemin (`scroll_item_id`, UNIQUE, supprimé avec l'objet) → `target_kind` ∈ {item, spell, building} + `target_id` ; `qty_out` 1..999 ; `resources` JSONB ; `consume_scroll` (défaut vrai) ; `at_capital` (défaut faux) ; `energy_cost` 0..1000.
- Idempotente.

## Gotchas
- `target_id` n'a pas de clé étrangère (cible polymorphe) : une cible supprimée laisse une recette orpheline (affichée « supprimé » en admin).

## Tests
`scripts/check-sql.sh` ; back `craftShop.test.ts`.
