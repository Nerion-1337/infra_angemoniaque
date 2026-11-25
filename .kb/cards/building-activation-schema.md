---
title: Migration 28 : conditions d activation des bâtiments
slug: building-activation-schema
status: done
updated: 2026-11-25
files:
  - db/28_activation_batiments.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 28 : conditions d'activation de la capacité d'un bâtiment.

## Business rules
- `buildings.activation` JSONB, défaut `{}` (= comportement historique) ; format `{ groups: [{ items, divine, spellId, resources, gold, minRank, ranks, consume }] }`, validé par le back.
- Idempotente.

## Gotchas
- La validation du contenu est côté back (`game/activation.ts`), pas en SQL.

## Tests
`scripts/check-sql.sh` ; back `buildingActivation.test.ts`.
