---
title: Monde Anges & Démons : migration 09_world2.sql (carte 300x300)
slug: world2-angel-demon
status: done
updated: 2026-11-24
files:
  - db/09_world2.sql
symbols:
  - db/09_world2.sql:maps
tests:
  - scripts/check-sql.sh
---
## Purpose
Adapte la base au monde 2 (Anges & Démons) : taille de la carte, capitales, portes, arrivées des portails humains, gardiens divins.
Fichier GÉNÉRÉ par `tools/gen_angel_demon_map.py` (mêmes coordonnées que `FEATURES2` du back).

## Business rules
- Carte 2 = 300×300 ; Bastion Infernal (75,150) côté démons, Sanctuaire (225,150) côté anges.
- Portes : Brèche de Soufre (démons), Arche de Grâce (anges) ; les 4 portails humains pointent vers leurs arrivées du monde 2.
- Gardiens divins : Balrog près du volcan démoniaque, Léviathan dans le lac de l'Ascension.
- Mises à jour ciblées par nom, rejouables.

## Gotchas
- S'applique après `08_world.sql` ; sur un volume existant, les personnages Ange/Démon gardent d'anciennes coordonnées (`make dev-reset` conseillé).
- L'unicité de case (`uq_cell`) peut refuser une mise à jour si une entité occupe déjà la case cible.

## Tests
`scripts/check-sql.sh` ; cohérence vérifiée côté back (`world2.test.ts`).
