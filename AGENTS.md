# AGENTS.md — ia_agent / infra

> Dépôt `infra` du projet `ia_agent`. Les règles générales (mémoire `kb`, cycle plan/code/tests/fiche, commits,
> web, outils `stack` et `gitpush`) sont dans `../AGENTS.md` : **relis-les**, elles s'appliquent ici.
> Ce fichier ne contient que ce qui est propre à ce dépôt.

## Rôle de ce dépôt
- Orchestration et configuration **Docker** pour l'ensemble du projet (définition des conteneurs pour `front/`, `back/` et les services socles).
- Découpage et gestion des deux cibles d'environnement : **développement** (`dev`) et **production** (`prod`).
- Gestion de la structure, des schémas et des migrations des bases de données.
- Configuration et maintenance des services d'infrastructure :
  - **PostgreSQL** : base de données relationnelle principale.
  - **Redis** : cache, sessions et files d'attente.
  - **Nginx** : reverse proxy, routage (`/` vers le front, `/api/` vers le back) et terminaison SSL/TLS en production.

## Stack et commandes
- **Stack** : Docker, Docker Compose, Nginx, PostgreSQL, Redis.
- **Environnements** :
  - Lancement dev : `docker compose -f docker-compose.dev.yml up`
  - Validation prod : `docker compose -f docker-compose.prod.yml config`
- **Tests** : lint des Dockerfiles (hadolint), validation syntaxique des fichiers compose et validation des migrations SQL (commande enregistrée via `kb init --test-cmd "<commande>"`).
- **Aucune** nouvelle dépendance, service ou image de base sans accord préalable.

## Interfaces avec les autres dépôts
- **`front/`** : ce dépôt fournit le `Dockerfile` de build/serve et l'intégration Nginx.
- **`back/`** : ce dépôt fournit le `Dockerfile` d'exécution, applique les schémas PostgreSQL et expose les accès réseaux (PostgreSQL, Redis) via les variables d'environnement.
- **Règle absolue** : ne modifie JAMAIS `../front` ou `../back` depuis ce dossier. Si une modification applicative est requise pour s'adapter à l'infra (ou inversement), documente le besoin et signale-le.

## Travail dans ce dépôt
- Branche `agent` (déjà créée). Commits : `gitsave "<message>"` lancé depuis CE dossier.
- Publier : `gitpush` depuis CE dossier. Je fais la Pull Request et le merge.
- Mémoire : `kb init` si `.kb/` n'existe pas encore dans ce dossier, puis le cycle habituel (`../AGENTS.md`).