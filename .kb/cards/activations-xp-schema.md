---
title: Migration 49 : XP totale accumulée, structure visible, éléments d'activation des structures
slug: activations-xp-schema
status: done
updated: 2026-11-28
files:
  - db/49_activations_xp_totale.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma de l'activation générique des structures, de l'XP totale accumulée par joueur et de la visibilité des structures sur la carte.

## Business rules
- `characters.xp_total` : trigger `trg_xp_total` (BEFORE INSERT OR UPDATE OF xp) ajoute toute hausse d'XP ; reprise = XP actuelle.
- `buildings.visible` (vrai par défaut).
- `buildings.activations` (JSONB, `[]`) : au premier passage, les portes des mondes reçoivent 1 objet divin de leur famille, consommé, `open_h_per_item` heures.

## Gotchas
- Idempotente ; la reprise des portes est gardée par l'absence de la colonne `activations`.

## Tests
`scripts/check-sql.sh`.
