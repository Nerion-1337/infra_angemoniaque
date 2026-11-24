---
title: Migration 20 : effets de sort, dégâts sur la durée, liens sort ↔ entités
slug: spell-engine-schema
status: done
updated: 2026-11-24
files:
  - db/20_moteur_sorts.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 20 : colonne des effets de sort, dégâts sur la durée en cours, liens sort ↔ objet / monture / bâtiment.

## Business rules
- `spells.effects` JSONB (défaut `{}` = sort historique).
- `spell_dots` : cible (character | monster | summon, id), sort, lanceur, dégâts par heure > 0, échéance `until` ; supprimés avec le sort.
- `entity_spells` : (kind ∈ item | mount | building, ref_id, spell_id, mode ∈ active | passive) unique ; supprimé avec le sort.
- Idempotente.

## Gotchas
- `entity_spells.ref_id` n'a pas de clé étrangère (cible polymorphe) ; les monstres restent dans `monster_spells`.

## Tests
`scripts/check-sql.sh` ; back `spellEngine.test.ts`.
