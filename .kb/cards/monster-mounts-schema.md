---
title: Migration 25 : monstres servant de monture (projection mounts, trigger sync_mount)
slug: monster-mounts-schema
status: done
updated: 2026-11-25
files:
  - db/25_monstres_montures.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 25 : fusion monstres / montures. Colonnes de monture sur `monsters`, lien 1:1 `mounts.monster_id`, reprise des
montures existantes en types de monstres, trigger de projection.

## Business rules
- `monsters` : `mountable` (faux), `locomotion TEXT[]` (`{land}`, CHECK 1 à 3 modes parmi land / air / water), `rarity` (commun, CHECK), `bonus_see`, `bonus_range`, `speed`, `carry`.
- `mounts.terrestrial` (vrai ; faux pour les aquatiques non volants historiques, ex. Navire) et `mounts.monster_id` UNIQUE → `monsters(id)` ON DELETE CASCADE.
- Reprise : chaque monture sans type crée un type montable (nom repris, suffixé « (monture n°X) » s'il est pris) ; les `character_mounts` gardent leur `mount_id`.
- Trigger `trg_sync_mount` (AFTER INSERT OR UPDATE sur `monsters`) : un type montable (sans `data.prototype`) insère ou met à jour sa ligne `mounts`.
- Idempotente : relancée, elle ne recrée ni type ni monture.

## Gotchas
- Le trigger est créé APRÈS la reprise : sinon l'insertion des types repris créerait une seconde ligne `mounts`.
- Une ligne `mounts` modifiée à la main hors trigger serait écrasée à la prochaine modification du type.

## Tests
`scripts/check-sql.sh` ; back `monsterMount.test.ts` (reprise sur la stack neuve, projection).
