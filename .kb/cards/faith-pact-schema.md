---
title: Migrations 44 et 45 : compositions de pacte (attributions max, changement 48 h), pactes par rang, prières, réglages ; paliers d'amélioration libres
slug: faith-pact-schema
status: done
updated: 2026-11-26
files:
  - db/44_foi_pactes.sql
  - db/45_pactes_limites_paliers.sql
symbols:
  -
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma de la foi et des pactes réglés en admin. Rejouable.

## Business rules
- Migration 45 : `pact_tiers.max_assign` (NULL = illimité, ≥ 1), `pacts.tier_changed_at` (dernier changement de composition), `stat_cost_rules.multis NUMERIC[]` repris de multi_1..3 (colonnes historiques gardées, plus lues). Idempotente.
- `pact_tiers` (nom unique, xp_hour / gold_hour ≥ 0, percent 1–100, duration_h ≥ 1, cooldown_h ≥ 0, sort) ; trois compositions par défaut (Faible 1/1/10 %, Moyen 3/3/20 %, Fort 5/5/30 %, 1 h, sans délai) si la table est vide.
- `pacts.tier_id` (`ON DELETE SET NULL`, pactes existants → composition la plus basse), `pacts.ready_at` ; index unique « un pacte actif par Humain » supprimé (limite par rang).
- `specializations.max_pacts` (NULL = règle par défaut) ; `faith_prayers` (journal des prières, supprimé avec la foi ou le personnage) ; prières « soin » effacées.
- `game_config.faith` et `game_config.pact` créés s'ils manquent, proches de l'ancien comportement (+2 XP / or par fidèle, une prière / 72 h ; Force + Agilité transférées).

## Tests
Volume neuf et suite d'intégration du back (283 tests).
