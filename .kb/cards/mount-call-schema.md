---
title: Migration 29 : montures invocables à pied, équipement des montures
slug: mount-call-schema
status: done
updated: 2026-11-26
files:
  - db/29_montures_invocables.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
**Historique : tables et triggers supprimés par la migration 43 (card `summon-ride-schema`).** Migration 29 : identifiant des montures possédées, lien invocation → monture / type de monstre, équipement des montures,
retour des PV et de l'énergie au renvoi.

## Business rules
- `character_mounts.id` (clé primaire, ajoutée aux lignes existantes).
- `summons.monster_id` (type d'origine, capacités ; SET NULL) et `summons.char_mount_id` (UNIQUE, monture possédée invoquée à pied ; CASCADE).
- `mount_equips` (monture possédée, partie ∈ 7 parties, objet) : une pièce par partie (clé primaire).
- Trigger `trg_summon_back_to_mount` (BEFORE DELETE sur `summons`) : recopie PV et énergie (≥ 0) sur la monture possédée.
- Idempotente.

## Gotchas
- La clé primaire est ajoutée seulement si absente (nom `character_mounts_pkey`).

## Tests
`scripts/check-sql.sh` ; back `mountCall.test.ts`.
