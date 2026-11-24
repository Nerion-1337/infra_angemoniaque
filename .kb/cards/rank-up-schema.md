---
title: Migration 21 : conditions de passage de rang et rang temporaire
slug: rank-up-schema
status: done
updated: 2026-11-24
files:
  - db/21_passage_de_rang.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Migration 21 : conditions de passage par rang et rang temporaire en cours.

## Business rules
- `specializations.requirements` JSONB (défaut `{}`) : objets, ressources, énergie, mode définitif / temporaire, durée, consommation.
- `characters.temp_rank` JSONB (NULL hors rang temporaire) : échéance + caractéristiques et rang d'avant.
- Idempotente.

## Gotchas
- Ne jamais vider `temp_rank` dans une migration (les joueurs perdraient leur retour au rang précédent).

## Tests
`scripts/check-sql.sh` ; back `rankUp.test.ts`.
