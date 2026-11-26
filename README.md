# angemoniaque-infra — DEV et PROD indépendants (aucun Node sur l'hôte)
| | DEV (`-f docker-compose.dev.yml`) | PROD (`-f docker-compose.prod.yml`) |
|---|---|---|
| Projet / conteneurs | angemoniaque-dev / ange-dev-* | angemoniaque-prod / ange-prod-* |
| Jeu | http://localhost:8080 | http://localhost |
| PgAdmin / Postgres | :5051 / :5433 | :5050 / interne |
| Données | volume pgdata_dev | volume pgdata |
Ils peuvent tourner en même temps sans s'écraser. `cp .env.example .env` d'abord. Commandes : voir Makefile.

## Connexion avec Google
Variables à ajouter dans `.env` (lu par le back) :
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` : console Google Cloud > API et services > Identifiants > « ID client OAuth » (type application Web).
- `PUBLIC_URL` : adresse publique du site sans `/` final (ex. `https://jeu.exemple.fr`).
- Dans la console Google, URI de redirection autorisée : `${PUBLIC_URL}/api/auth/google/callback` (en dev : `http://localhost:8080/api/auth/google/callback`).

Sans ces deux clés, la connexion Google est **simulée** (email seulement, jamais pour le compte admin ni un compte à mot de passe) ; la prod la coupe (`GOOGLE_MOCK=0` dans `docker-compose.prod.yml`) : le bouton disparaît tant que les clés manquent.
