---
title: Migration 43 : fin des montures, monte des invocations, délais de relance ; migrateur sur volume neuf
slug: summon-ride-schema
status: done
updated: 2026-11-26
files:
  - db/43_invocations_montees.sql
  - scripts/migrate.sh
symbols:
  - db/43_invocations_montees.sql:summon_death_cooldown
tests:
  - scripts/check-sql.sh
---
## Purpose
Supprime tout ce qui touchait aux montures (décision de l'humain du 2026-11-26) et ajoute la monte d'une invocation et les
délais de relance des sorts. Rejouable.

## Business rules
- Ajoute `characters.riding_summon_id` (unique, `ON DELETE SET NULL`), `summons.spell_id`, `spells.cooldown_h`, `monsters.resummon_delay_h` (NUMERIC ≥ 0, heures), table `spell_cooldowns (character_id, spell_id, ready_at)`.
- Trigger `summon_death_cooldown` (BEFORE DELETE sur `summons`) : invocation supprimée à 0 PV avec un sort et un type → échéance = maintenant + `resummon_delay_h`, la plus lointaine gardée.
- Sorts `effects.summon.kind = mount` → `monster` (même `refId`, déjà l'id du type).
- Supprimés : `mounts`, `character_mounts`, `mount_equips`, `summons.char_mount_id`, `positions.mount_id`, triggers `sync_mount` / `summon_back_to_mount`, liens et invocations temporaires de kind `mount`, annonces de marché de montures, clé `mounts` des kits de départ, parchemin de navire, colonnes `monsters.speed / carry / bonus_see / bonus_range`, kind « monture » des `usable_by`.
- `scripts/migrate.sh` : journal vide ET effet du 43 présent (= volume neuf, l'entrypoint a tout joué) → tous les fichiers sont enregistrés sans être rejoués. Les volumes déjà suivis ne changent pas de comportement.

## Gotchas
- Les migrations 18, 25, 29 et 35 référencent les montures : elles ne doivent plus jamais être rejouées après le 43 (d'où la règle du migrateur).
- Les montures possédées par les joueurs sont perdues (pas de conversion, choix de l'humain).

## Tests
Volume neuf (entrypoint + migrateur : 43 en « baseline ») ; base arrêtée au 42 avec journal → seul le 43 est appliqué (montures, kits, parchemin de navire disparus) ; 43 rejoué deux fois sans erreur ; suite d'intégration du back (280 tests).
