---
title: Rattrapage des migrations sur volume existant (service migrator)
slug: schema-migrations-catchup
status: done
updated: 2026-11-21
files:
  - scripts/migrate.sh
  - docker-compose.dev.yml
  - docker-compose.prod.yml
  - Makefile
  - db/11_bestiaire.sql
  - db/12_monstre_details.sql
  - db/13_monstre_capacites.sql
symbols:
  - scripts/migrate.sh:marker
  - docker-compose.dev.yml:migrator
  - docker-compose.prod.yml:migrator
  - Makefile:dev-migrate
tests:
  - ../docker-compose.test.yml
---
## Purpose
Sur un volume Postgres **déjà créé** (dev/prod), les migrations `db/*.sql` ne sont jamais
appliquées par l'entrypoint Postgres (qui ne les joue que sur volume vierge). Résultat : une
colonne ajoutée par une migration récente (ex. `accounts.role`, `10_admin.sql`) est absente et
le back renvoie 500 « Erreur interne » (ex. à l'inscription). Ce service `migrator` rattrape
automatiquement les migrations manquantes à chaque `make dev-up` / `prod-up`, sans casser un
volume partiellement migré.

## How it works
- Service compose `migrator` (image `postgres:16`, `command: [sh, /scripts/migrate.sh]`), monté
  `./db` et `./scripts` en lecture seule, `depends_on: postgres: service_healthy`, `env_file: .env`.
- `scripts/migrate.sh` :
  1. Attend que `psql -h $PGH` réponde (volume vierge : initdb de l'entrypoint d'abord).
  2. Crée `game_schema.schema_migrations (name PK, applied_at)` (idempotent).
  3. Pour chaque `db/*.sql` dans l'ordre **lexicographique** :
     - déjà dans `schema_migrations` → saute (`ok (applied)`).
     - sinon, marqueur du fichier = « t » → c'est un fichier **historique** déjà présent dans le
       volume : enregistre-le dans le suivi SANS le rejouer (`ok (marker) — baseline`).
     - sinon → l'applique avec `psql -v ON_ERROR_STOP=1 -f`, puis l'enregistre.
- La fonction `marker <fichier>` mappe chaque migration à une requête « l'artefact distinctif du
  fichier existe-t-il ? » (table via `to_regclass`, colonne via `information_schema.columns`,
  état de données pour `09_world2.sql`). Un fichier inconnu → `SELECT false` (appliqué s'il manque).

## Entry points
- `docker-compose.dev.yml` / `docker-compose.prod.yml` : service `migrator` (déclenché par
  `make dev-up` / `make prod-up`, ou `make dev-migrate` / `make prod-migrate` en repassant
  `up -d migrator`).
- `docker-compose.test.yml` (racine) : même service + `/scripts` aussi monté dans `postgres`
  pour pouvoir simuler un volume partiellement migré depuis `stack exec`.

## Data flow
- Lit l'état du volume (artefacts via `to_regclass` / `information_schema`) et écrit
  `game_schema.schema_migrations`. N'efface jamais de données. Sur volume vierge : no-op
  (l'entrypoint a tout joué, tout bascule en `ok (marker)`). Sur volume partiel : joue seulement
  les fichiers manquants, dans l'ordre, puis enregistre chacun.

## Tests
- Syntaxe (test_cmd du dépôt) : `bash -n scripts/migrate.sh` + parse YAML de tous les compose.
- Intégration (stack de test, `docker-compose.test.yml`) :
  1. `stack up` → service `migrator` tourne, baseline no-op, `schema_migrations` rempli.
  2. Simulation d'un volume **partiellement migré** : on repasse `postgres` avec un
     sous-ensemble de `db/*.sql` (ex. `01`→`09` sans `10_admin.sql`/`11_bestiaire.sql`),
     on relance le migrator → il n'applique que les fichiers manquants et complète la base.
  3. On vérifie que les artefacts nouveaux (`accounts.role`, tables bestiaire) existent.
- Vérifie que le volume n'est pas altéré (pas de rejeu en double, pas d'effacement de données).

- **Marqueurs par fichier** (dans `migrate.sh`) : 10 → `accounts.role`, 11 →
  `monster_loot`, 12 → `monster_spells`, 13 → disparition de `monster_auras`,
  14 → colonne `spells.usable_by` (la présence d'une seule table/colonne suffit à
  baseliner le fichier ; un fichier **partiellement** appliqué d'avant le suivi reste un
  cas à traiter à la main, voir l'incident volume dev 2026-11).

## Gotchas
- **Ordre lexicographique obligatoire** : les fichiers s'appliquent dans l'ordre `db/*.sql` ;
  un `12_*.sql` vient après `11_*.sql`. Ne jamais renommer un fichier déjà appliqué.
- **Marqueur = artefact distinctif et idempotent** : ajouter un nouveau fichier `NN_*.sql`
  exige d'ajouter sa ligne dans `marker()` (artefact créé par ce fichier, pas un artefact
  partagé). Sans marqueur, un volume **historique** le rejouerait même s'il l'avait déjà.
- **Rejeu partiel** : si un fichier échoue à moitié (`ON_ERROR_STOP` stoppe le script), il n'est
  PAS enregistré → il sera rejoué au prochain lancement et pourra échouer sur un artefact déjà
  créé. On doit alors terminer la migration à la main puis `INSERT INTO schema_migrations(name)`.
- **Une instance par volume** : le service est idempotent mais deux `migrator` simultanés sur le
  même volume peuvent se croiser ; ne pas exécuter `migrate.sh` à la main pendant que le service tourne.
- L'entrypoint `initdb` reste monté (`./db:/docker-entrypoint-initdb.d:ro`) : il joue les
  migrations sur volume vierge ; le migrator assure le reste. Les deux doivent rester en accord.
