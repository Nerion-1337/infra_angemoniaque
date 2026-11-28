---
title: Migration 48 : zones et réapparition des structures, portes des mondes, Royaume des Morts 150 × 150, pactes des demi-dieux, règles générales
slug: structures-gates-schema
status: done
updated: 2026-11-28
files:
  - db/48_structures_portes.sql
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma du lot du 2026-11-28 : zones autour des structures (paix, sans construction), reconstruction des structures détruites, portes des mondes activables, Royaume des Morts agrandi avec sa porte centrale, pactes des demi-dieux, règles générales.

## Business rules
- `buildings` : `peace_radius`, `nobuild_radius`, `respawn`, `respawn_delay_h`, `respawn_limits`, `home`, `destroyed_at`, `realm`, `leads_to`, `open_h_per_item` (24), `open_until`.
- Au premier passage seulement (colonne `realm` absente) : mondes des 6 portes, portes des Hommes / Démons / Anges destructibles (1000 points, reconstruites 48 h après).
- `maps` 3 : 100 → 150 ; porte des Âmes (realm dead, invulnérable) en (75, 75).
- `pact_tiers.realm` (ethereal / demigod), unicité (realm, name), compositions copiées pour les demi-dieux ; `specializations.pact_patron` (vrai pour « Demi-Dieu »).
- `game_config` : `death_loss_pct` 25, `gate_bonus` vide.

## Gotchas
- Idempotente : les mises à jour de données sont gardées par la présence des colonnes ; un réglage admin n'est pas écrasé au redémarrage.

## Tests
`scripts/check-sql.sh`.
