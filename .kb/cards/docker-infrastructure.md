---
title: Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations
slug: docker-infrastructure
status: done
updated: 2026-11-26
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
  - README.md
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

- Nginx transmet `X-Forwarded-Host` / `X-Forwarded-Proto` au back (retour de la connexion Google) ; la prod force `GOOGLE_MOCK=0` (pas de connexion Google simulée).
- Nginx : `X-Real-IP $remote_addr` vers le back (limitation de débit) ; code admin servi après `auth_request` vers `/auth/admin-asset` (`/assets-admin/` en prod, `/src/admin/` en dev) ; prod : CSP (scripts du site, polices Google), X-Frame-Options DENY, nosniff, Referrer-Policy, Permissions-Policy, server_tokens off.
- README : section Sécurité (JWT_SECRET, amorçage admin, débit, anti-robot).
## Gotchas
- Nginx résout `backend` / `frontend` par le DNS Docker (`resolver 127.0.0.11 valid=10s`) avec des variables dans `proxy_pass` : un conteneur recréé par `up -d --build` change d'IP ; avec un nom fixe, Nginx gardait l'ancienne adresse → 502 à la connexion jusqu'à son redémarrage (reproduit puis corrigé le 2026-11-25). Avec une variable, le préfixe `/api` est retiré par `rewrite … break` (paramètres conservés).
- Copies Windows (CRLF) : le migrator retire les `\r` (`sed 's/\r$$//'`, `$$` = échappement compose) avant d'exécuter `migrate.sh` ; `.gitattributes` (eol=lf) ne réécrit pas les fichiers déjà extraits.
- Renuméroter ou réordonner les migrations casse une initialisation neuve.
- `BACKEND_PATH` / `FRONTEND_PATH` supposent les dépôts côte à côte.
- Portainer monte le socket Docker : prod seulement.
- Pas de TLS ici (affaire d'exploitation).

## Tests
`scripts/check-sql.sh` (toutes les migrations sur une base vierge, `ON_ERROR_STOP`) ; CI : `config -q` des fichiers compose, `nginx -t` ; test local `kb` : syntaxe des scripts + YAML.
