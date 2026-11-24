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
Migration 16 : objets divins gérés comme les autres objets (ligne `items` de rareté divin) et familles libres au-delà de
relique / arcane / artefact, chacune avec un plafond d'exemplaires.

## Business rules
- `divine_families(key, name, cap)` : clé `^[a-z][a-z0-9_]{1,29}$`, plafond NULL = illimité ; reprise des 3 familles du jeu avec les plafonds de `game_config.divine_caps`.
- `divine_items.kind` n'est plus limité à 3 valeurs : clé étrangère vers `divine_families` (renommage en cascade).
- `items.divine_family` relie un objet du catalogue à sa famille ; `divine_items.item_id` relie chaque exemplaire à son objet modèle.
- Reprise : un objet modèle « Relique » / « Arcane » / « Artefact » par famille sans objet, puis rattachement des exemplaires orphelins.
- Idempotente.

## Gotchas
- Ne jamais remplacer la reprise par un UPDATE (écraserait les plafonds saisis en admin).
- `game_config.divine_caps` n'est plus qu'un repli.

## Tests
`scripts/check-sql.sh` ; rejouée deux fois sur la stack ; back `adminPlayersDivine.test.ts` (aucun exemplaire sans objet).
