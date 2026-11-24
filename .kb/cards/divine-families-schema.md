---
title: Familles divines (migration 16) : divine_families, items.divine_family, divine_items.item_id
slug: divine-families-schema
status: done
updated: 2026-11-24
files:
  - db/16_familles_divines.sql
symbols:
tests:
  - scripts/check-sql.sh
---
## Purpose
Permet de gérer les objets divins comme les autres objets (une ligne `items` de rareté « divin ») et de créer d'autres familles
que relique / arcane / artefact, chacune avec son plafond global d'exemplaires.

## How it works
`db/16_familles_divines.sql` : `divine_families(key PK CHECK ^[a-z][a-z0-9_]{1,29}$, name, cap NULL = illimité)` seedée avec les
3 familles du jeu et les plafonds de `game_config.divine_caps` ; suppression du CHECK historique sur `divine_items.kind` et ajout
d'une clé étrangère `divine_items_kind_fk` vers `divine_families(key)` ; `items.divine_family` (FK) ; `divine_items.item_id` (FK
`items`) ; reprise : un objet modèle « Relique » / « Arcane » / « Artefact » (rareté divin) par famille sans objet, puis rattachement
des exemplaires orphelins.

## Entry points
Entrypoint Postgres (volume neuf) ou `migrator` (fichier nouveau : appliqué s'il manque). CI back : rejoue `db/*.sql`.

## Data flow
Lu/écrit par `back/src/routes/admin/items.ts` et `game/content.ts:divineCap` (card back `admin-players-divine`).

## Tests
Rejouée deux fois sur la stack (entrypoint puis migrator : NOTICE « already exists / does not exist », OK) ;
`back/test/integration/adminPlayersDivine.test.ts` vérifie la reprise (aucun exemplaire sans `item_id`).

## Gotchas
- Idempotente (IF NOT EXISTS, ON CONFLICT, garde `pg_constraint`) : ne jamais remplacer le seed par un UPDATE (écraserait les plafonds saisis en admin).
- `game_config.divine_caps` n'est plus la source des plafonds (repli seulement si la table manque).
