---
title: Migrations 38-40 : carte des ressources par monde, connexion Google, forum et pages légales
slug: forum-google-schema
status: done
updated: 2026-11-26
files:
  - db/38_carte_par_monde.sql
  - db/39_connexion_google.sql
  - db/40_forum_annonces.sql
  - nginx/nginx.conf
  - nginx/nginx.dev.conf
  - docker-compose.prod.yml
  - README.md
symbols:
  - 
tests:
  - scripts/check-sql.sh
---
## Purpose
Schéma de la carte des ressources par monde (38), de la connexion Google (39), du forum public et des pages légales (40) ; en-têtes Nginx et réglages d'environnement associés.

## Business rules
- 38 : `characters.map_worlds INT[]` remplace le booléen `map_upgrade` (repris vers le monde de la capitale de la race, puis colonne supprimée) ; un parchemin « Carte des ressources — <monde> » par monde (`data = { kind: 'resource_map', map_id }`, rareté rare, prix 500, hors boutique).
- 39 : `accounts.google_sub` (unique si non NULL) ; `password_hash` peut être NULL (compte Google).
- 40 : `forum_categories` (kind, read_access, post_access, races, min_rank, locked, hidden ; CHECK des valeurs), `forum_topics`, `forum_posts`, `forum_reports` (un par membre et par message), `legal_pages` (clé, titre, texte, version) ; `accounts.tos_version`, `tos_accepted_at`, `forum_muted_until` ; 8 catégories et 5 pages légales d'exemple (mentions légales à compléter entre crochets).
- Nginx (dev et prod) : `X-Forwarded-Host $http_host` et `X-Forwarded-Proto $scheme` vers le back (adresse de retour Google).
- Prod : `GOOGLE_MOCK: "0"` forcé sur le back (jamais de connexion Google simulée) ; `README.md` (section « Connexion avec Google ») documente GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, PUBLIC_URL et l'URI de redirection (`.env.example` n'est pas modifiable par l'agent : garde-fou de gitsave).

## Gotchas
- Migrations idempotentes : 38 teste l'existence de `map_upgrade` avant de la reprendre ; les graines ne s'insèrent que si la table est vide / la clé absente.

## Tests
Rejouées deux fois sur un Postgres 16 jetable ; intégration back (`equipMap`, `forum`).
