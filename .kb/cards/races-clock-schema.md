---
title: Migrations 17-18 : apparition, limites et équipement de départ par race, horloge du monde, trigger de création aligné
slug: races-clock-schema
status: done
updated: 2026-11-24
files:
  - db/17_races_apparition_horloge.sql
  - db/18_depart_par_race.sql
symbols:
tests:
  - scripts/check-sql.sh
---
## Purpose
Migrations 17 et 18 : réglages des races (zone d'apparition, limites, équipement de départ), horloge du monde persistante,
et trigger de création de personnage aligné sur ces réglages avec exemption du compte admin.

## Business rules
- `races` : `spawn_map_id` (NULL = capitale), `spawn_x`, `spawn_y`, `spawn_radius` (défaut 4, 0..100), `max_per_account` (défaut 3, NULL = illimité), `max_total` (NULL = illimité), `start_kit` JSONB (défaut `{}`).
- Reprise 18 : les races existantes reçoivent le kit historique (150 or, 6 objets au sac, Destrier) ; un kit déjà réglé n'est jamais écrasé.
- `game_clock` : une seule ligne (`id = 1`), `last_tick_at` initialisé à `now()` à la création.
- `chk_char_limit()` : compte admin → aucune règle ; sinon même race obligatoire, `max_per_account` de la race (3 si la race est absente de `races`), `max_total`.
- Idempotentes.

## Gotchas
- PL/pgSQL : variables scalaires (`mpa`, `mt`), jamais d'affectation dans un RECORD non initialisé.
- Ne jamais remettre `game_clock.last_tick_at` à `now()` dans une migration ultérieure (effacerait les heures dues).

## Tests
`scripts/check-sql.sh` ; rejouées deux fois sur la stack ; back `racesClock.test.ts` et `startKit.test.ts`.
