---
title: Migration 50 : types de structures (héritage), apparence, or du coffre
slug: struct-types-schema
status: done
updated: 2026-11-28
files:
  - db/50_types_structures_or_coffre.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma des types de structures (réglages globaux suivis par les structures posées), de l'apparence et de l'or déposé au coffre.

## Business rules
- `buildings` : `is_type`, `type_id`, `overrides` (TEXT[]), `own_data` (JSONB), `model` (clé ^[a-z0-9_]{1,40}$).
- Reprise (une seule fois, gardée par la colonne `type_id`) : types « Capitale » (d'après l'Hôtel de ville, sans race) et « Porte » (d'après la Brèche, sans `to`) ; chaque capitale / porte s'y rattache ; colonnes et clés de `data` différentes deviennent individuelles.
- `characters.chest_gold` (≥ 0).

## Gotchas
- Idempotente.

## Tests
`scripts/check-sql.sh`.
