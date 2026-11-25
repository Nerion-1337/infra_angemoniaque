---
title: Migrations 21 et 24 : passage de rang (deux voies), rang temporaire, réapparition des monstres
slug: rank-up-schema
status: done
updated: 2026-11-25
files:
  - db/21_passage_de_rang.sql
  - db/24_rangs_respawn.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 21 : conditions de passage par rang et rang temporaire en cours. Migration 24 : deux voies de passage, réapparition des monstres réglée par type.

## Business rules
- `specializations.requirements` JSONB (défaut `{}`) : `{ permanent, temporary }`, chaque voie `null` ou { objets, ressources, énergie, consommation } (+ `durationH` pour la voie temporaire).
- Migration 24 : convertit l'ancien format `{ mode, durationH, … }` vers la voie correspondante ; ne touche que l'ancien format (idempotente).
- `monsters.respawn` BOOL (défaut vrai) et `monsters.respawn_limits` JSONB (défaut `[]`, `[{ kind: item|spell|resource, ref, max }]`) ; le délai reste `reincarnate_delay_h` (migration 12).
- `characters.temp_rank` JSONB (NULL hors rang temporaire) : échéance + caractéristiques et rang d'avant.
- Idempotente.

## Gotchas
- Ne jamais vider `temp_rank` dans une migration (les joueurs perdraient leur retour au rang précédent).

## Tests
`scripts/check-sql.sh` ; back `rankUp.test.ts`, `monsterRespawn.test.ts` ; migration 24 jouée sur la stack neuve (initdb).
