---
title: Monde Anges & Démons : migration 09_world2.sql (carte 300x300)
slug: world2-angel-demon
status: done
updated: 2026-10-21
files:
  - db/09_world2.sql
symbols:
  - db/09_world2.sql:maps
tests:
  - scripts/check-sql.sh
---
## Purpose
Adapte la base au nouveau monde 2 : taille de la carte, capitales, portes, arrivées des portails humains, gardiens divins. Fichier **généré** par `tools/gen_angel_demon_map.py` (mêmes coordonnées que `FEATURES2` du back).

## How it works
`UPDATE` ciblés par nom, rejouables : `maps` id 2 → 300x300 ; Bastion Infernal (75,150) / Sanctuaire (225,150) ; Brèche de Soufre (démons) / Arche de Grâce (anges) ; `data.to` des 4 portails humains (08_world.sql) ; Balrog près du volcan démoniaque, Léviathan dans le lac de l'Ascension (angélique).

## Gotchas
- S'applique après `08_world.sql` (ordre lexicographique). Sur un volume existant il ne se rejoue pas tout seul : `make dev-reset` (les personnages Ange/Démon existants seraient sur d'anciennes coordonnées).
- Pas de `ON DELETE`/contrainte nouvelle ; `uq_cell` peut refuser un UPDATE si une entité occupe déjà la case cible (base non vierge).
