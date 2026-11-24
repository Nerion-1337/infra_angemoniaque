---
title: Rattrapage des migrations sur volume existant (service migrator)
slug: schema-migrations-catchup
status: done
updated: 2026-11-24
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
Rattrapage des migrations sur un volume Postgres déjà créé (dev/prod) : le service `migrator` applique les fichiers `db/*.sql`
manquants à chaque `make dev-up` / `prod-up`, sans casser un volume partiellement migré.

## Business rules
- Fichiers traités en ordre lexicographique ; chaque fichier appliqué est enregistré dans `game_schema.schema_migrations`.
- Déjà enregistré → sauté ; marqueur présent (artefact distinctif du fichier) → enregistré SANS rejeu (« baseline ») ; sinon appliqué avec `ON_ERROR_STOP` puis enregistré.
- Un fichier sans marqueur (nouveau) est appliqué s'il manque ; il doit donc être idempotent ou ne jamais avoir existé sur un volume historique.
- Le migrator n'efface jamais de données ; sur volume neuf il ne fait qu'enregistrer.
- Une seule instance par volume.

## Gotchas
- Ne jamais renommer un fichier déjà appliqué.
- Un fichier qui échoue à moitié n'est pas enregistré : le terminer à la main puis `INSERT INTO schema_migrations(name)`.
- Le marqueur d'un fichier doit être un artefact qu'IL crée (pas un artefact partagé).
- Copies Windows (CRLF) : voir `docker-infrastructure` (le migrator retire les `\r`).
- L'entrypoint `initdb` et le migrator doivent rester d'accord sur l'ensemble des fichiers.

## Tests
Syntaxe (`bash -n scripts/migrate.sh` + YAML) ; vérifié sur la stack (baseline sur volume neuf, volume partiel complété) ; test réel 2026-11-24 avec script et SQL en CRLF.
