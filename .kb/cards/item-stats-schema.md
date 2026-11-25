---
title: Migration 26 : bonus de caractéristiques des objets (trigger trg_item_bonus), armure magique de base
slug: item-stats-schema
status: done
updated: 2026-11-25
files:
  - db/36_portee_armes.sql
  - db/26_objets_caracteristiques.sql
  - db/32_equipement_carte.sql
  - db/34_taille_coffre.sql
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
- Migration 32 : `items.two_handed` (arcs et `data.hands = 2` repris) ; types « bow / mains / tete / torse / pieds / collier / bague » ramenés à weapon / head / chest / foot / amulet / ring ; un arc équipé passe en main principale si les deux mains sont libres, sinon au sac ; `characters.map_upgrade` ; `game_config.map_upgrade_price` = 500. Idempotente.
- Migration 34 : `monsters.size` (1 à 3, défaut 1).
- Migration 36 : `items.reach` (1 à 20, défaut 1) et `items.full_power_at` (NULL ou 1 ≤ N < reach, CHECK `chk_item_reach`).

## Gotchas
- Le retrait utilise `applied`, jamais les bonus actuels de l'objet (l'admin peut les avoir changés entre-temps).
- Une mise à jour qui ne touche pas `equipped_slot` ne déclenche rien (UPDATE OF).

## Tests
`scripts/check-sql.sh` ; back `itemStats.test.ts`.
