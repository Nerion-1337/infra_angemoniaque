---
title: Migration 27 : modes des sorts liés (au coup porté, à l attaque reçue) et invocations temporaires
slug: spell-summon-schema
status: done
updated: 2026-11-26
files:
  - db/27_invocations_liens.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 27 : modes d'application des sorts liés à un élément et suivi des invocations temporaires.

## Business rules
- `entity_spells.mode` ∈ {active, passive, on_hit, on_struck} (contrainte `chk_entity_spells_mode`, remplace la contrainte de la migration 20).
- `spell_summons` : lanceur (supprimé avec le personnage), kind ∈ {monster, item, building} (`mount` retiré par la migration 43), `ref_id` (summons.id, mounts.id, items.id ou buildings.id selon le kind), `qty` ≥ 1, échéance `until` (index).
- Idempotente.

## Gotchas
- `ref_id` n'a pas de clé étrangère (plusieurs tables possibles) : le retrait au tick doit tolérer un élément déjà disparu.

## Tests
`scripts/check-sql.sh` ; back `spellSummon.test.ts`.
