---
title: Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations
slug: docker-infrastructure
status: done
updated: 2026-11-24
files:
  - docker-compose.yml
  - docker-compose.dev.yml
  - docker-compose.prod.yml
  - nginx/nginx.conf
  - nginx/nginx.dev.conf
  - db/01_init.sql
  - db/02_extra.sql
  - db/03_features.sql
  - db/04_guild_order.sql
  - db/05_rank_order.sql
  - db/06_default_rank.sql
  - db/07_forum_perms.sql
  - scripts/check-sql.sh
  - scripts/backup-db.sh
  - Makefile
  - .env.example
symbols:
  - docker-compose.dev.yml:angemoniaque-dev
  - docker-compose.prod.yml:angemoniaque-prod
  - nginx/nginx.conf:proxy_pass
  - nginx/nginx.dev.conf:proxy_pass
  - db/01_init.sql:game_schema
  - db/02_extra.sql:accounts
  - db/03_features.sql:summons
  - db/04_guild_order.sql:sort_order
  - db/05_rank_order.sql:sort_order
  - db/06_default_rank.sql:default_rank_id
  - db/07_forum_perms.sql:write_ranks
  - scripts/check-sql.sh:ON_ERROR_STOP
  - scripts/backup-db.sh:pg_dump
  - Makefile:dev-up
tests:
  - scripts/check-sql.sh
---
## Purpose
Orchestration Docker du projet : environnements dev et prod indépendants (Postgres 16, Redis 7, backend, frontend, Nginx, outils),
migrations SQL ordonnées du schéma `game_schema`, scripts d'exploitation et Makefile.

## Business rules
- Dev (`angemoniaque-dev`, conteneurs `ange-dev-*`) et prod (`angemoniaque-prod`) tournent en parallèle : projets, ports et volumes distincts (dev : 8080 jeu, 5433 Postgres, 5051 PgAdmin ; prod : 80, 5050 PgAdmin, 9000 Portainer).
- Nginx : `/api/` → backend:3000 avec le préfixe RETIRÉ et l'en-tête WebSocket ; `/` → frontend (fichiers statiques en prod, Vite HMR en dev).
- `node_modules` uniquement dans des volumes nommés : l'hôte ne voit jamais les dépendances.
- Migrations `db/*.sql` en ordre lexicographique : jouées par l'entrypoint Postgres sur volume NEUF, rattrapées par le service `migrator` sur volume existant (un nouveau fichier n'exige pas de `dev-reset`).
- Secrets (`JWT_SECRET`, identifiants Postgres et PgAdmin) dans `.env` (hors Git) ; `.env.example` = valeurs de dev ; la prod doit en avoir d'autres.
- Ce dépôt ne modifie jamais `../front` ni `../back` : un besoin côté application est signalé, pas codé ici.
- Le Makefile est le point d'entrée unique (`dev-up`, `prod-up`, `dev-migrate`, `test-*`…).

## Gotchas
- Copies Windows (CRLF) : le migrator retire les `\r` (`sed 's/\r$$//'`, `$$` = échappement compose) avant d'exécuter `migrate.sh` ; `.gitattributes` (eol=lf) ne réécrit pas les fichiers déjà extraits.
- Renuméroter ou réordonner les migrations casse une initialisation neuve.
- `BACKEND_PATH` / `FRONTEND_PATH` supposent les dépôts côte à côte.
- Portainer monte le socket Docker : prod seulement.
- Pas de TLS ici (affaire d'exploitation).

## Tests
`scripts/check-sql.sh` (toutes les migrations sur une base vierge, `ON_ERROR_STOP`) ; CI : `config -q` des fichiers compose, `nginx -t` ; test local `kb` : syntaxe des scripts + YAML.
