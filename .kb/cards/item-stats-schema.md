---
title: Migration 26 : bonus de caractéristiques des objets (trigger trg_item_bonus), armure magique de base
slug: item-stats-schema
status: done
updated: 2026-11-25
files:
  - db/26_objets_caracteristiques.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 26 : bonus de caractéristiques des objets reportés sur la fiche du personnage, armure magique de base, bonus
d'armure magique pour l'occupant d'un bâtiment.

## Business rules
- `characters.magic_armor` (0), `items.bonuses` JSONB (`{}`), `character_items.applied` JSONB (ce qui a été ajouté à l'équipement), `buildings.bonus_magic_armor` (0).
- Trigger `trg_item_bonus` (BEFORE INSERT, UPDATE OF equipped_slot, DELETE sur `character_items`) : équipé → `applied` = bonus de l'objet, ajoutés à la fiche ; déséquipé ou ligne portée supprimée → `applied` retiré.
- `apply_item_bonus` : PV max ≥ 1, autres ≥ 0 ; réserves (PV, énergie, énergie divine) ramenées sous leur max.
- Idempotente.

## Gotchas
- Le retrait utilise `applied`, jamais les bonus actuels de l'objet (l'admin peut les avoir changés entre-temps).
- Une mise à jour qui ne touche pas `equipped_slot` ne déclenche rien (UPDATE OF).

## Tests
`scripts/check-sql.sh` ; back `itemStats.test.ts`.
