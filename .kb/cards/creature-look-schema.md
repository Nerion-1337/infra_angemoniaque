---
title: Migration 41 : design 3D et icône des types de monstres
slug: creature-look-schema
status: done
updated: 2026-11-26
files:
  - db/41_designs_icones.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Design 3D et icône d'un type de monstre (admin « Monstres »).

## Business rules
- `monsters.model` et `monsters.icon` : clés en minuscules [a-z0-9_] (1-40) ou NULL (= automatique côté front) ; CHECK `chk_monster_look`.
- Recopiés sur le monstre posé (admin) ou apparu (spawn) ; la carte reprend sinon ceux du prototype (`data.prototype`) ; une invocation (montée ou non) prend ceux de leur type.

## Gotchas
- Idempotente (ADD COLUMN IF NOT EXISTS, contrainte ajoutée une fois).

## Tests
Rejouée deux fois sur un Postgres 16 jetable ; intégration back `test/integration/appearance.test.ts`.
