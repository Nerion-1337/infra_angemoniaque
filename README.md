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

## Sécurité (anti-spam, anti-robot, accès admin)
- `JWT_SECRET` (dans `.env`, 16 caractères minimum, jamais une valeur d'exemple) : sans lui, le back prend un secret aléatoire (sessions perdues au redémarrage) au lieu d'un secret connu.
- Compte admin : l'email `ADMIN_EMAIL` ne devient admin que s'il n'existe encore AUCUN administrateur (amorçage unique). Créez-le dès la mise en ligne.
- Droits admin / modérateur relus en base à chaque requête (un compte rétrogradé perd l'accès immédiatement).
- Code de l'interface admin : paquet séparé (`/assets-admin/` en prod, `/src/admin/` en dev) servi par Nginx seulement si le back valide le cookie admin (`auth_request` → `/auth/admin-asset`).
- Limitation de débit (Redis) par IP (`X-Real-IP` posé par Nginx) et par compte : inscriptions, connexions (verrou de 15 min après 8 échecs sur un email), messages, forum. `RATE_LIMIT=0` la coupe (déconseillé).
- Inscription : mot de passe fort (12 caractères, 3 types, pas de mot courant ni de suite), champ piège, preuve de travail calculée par le navigateur (`POW_BITS`, 16 par défaut ; `BOT_CHECK=0` la coupe).
- Nginx (prod) : CSP, `X-Frame-Options DENY`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`. Derrière un autre proxy (CDN, TLS), faites-lui transmettre l'IP réelle, sinon tous les visiteurs partagent la même limite.
