---
title: Migration 17 : zone d'apparition et limites par race, horloge du monde, trigger de création aligné
slug: races-clock-schema
status: done
updated: 2026-11-24
files:
  - db/17_races_apparition_horloge.sql
symbols:
tests:
  - scripts/check-sql.sh
---
## Purpose
Colonnes de réglage des races (apparition, limites), table `game_clock` de l'horloge persistante, et trigger historique de
création de personnage aligné sur ces réglages avec exemption du compte admin.

## How it works
- `races` : `spawn_map_id` (FK maps, NULL = capitale), `spawn_x`, `spawn_y`, `spawn_radius` (défaut 4, 0..100), `max_per_account`
  (défaut 3 = règle historique, NULL = illimité), `max_total` (NULL = illimité).
- `game_clock(id=1, last_tick_at)` seedée à `now()` : le back rattrape un tick par heure pleine écoulée depuis cette date.
- `chk_char_limit()` (CREATE OR REPLACE, trigger `trg_char_limit` de 01_init inchangé) : compte `role='admin'` → aucune règle ;
  sinon même race obligatoire, `max_per_account` de la race (3 si la race n'est pas dans `races`), `max_total`.

## Entry points
Entrypoint Postgres / `migrator` (fichier nouveau). Back : card `races-spawn-clock`.

## Data flow
Lu par `back/src/game/clock.ts`, `spawn.ts`, `routes/characters.ts`, `routes/admin/races.ts`.

## Tests
Rejouée deux fois sur la stack (entrypoint puis migrator) ; `back/test/integration/racesClock.test.ts` (limites, admin multi-races, horloge).

## Gotchas
- PL/pgSQL : ne pas affecter les champs d'un RECORD non initialisé (erreur) — variables scalaires `mpa`, `mt`.
- Idempotente ; ne jamais remettre `game_clock.last_tick_at` à `now()` dans une migration ultérieure (effacerait les heures dues).
