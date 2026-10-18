# angemoniaque-infra — DEV et PROD indépendants (aucun Node sur l'hôte)
| | DEV (`-f docker-compose.dev.yml`) | PROD (`-f docker-compose.prod.yml`) |
|---|---|---|
| Projet / conteneurs | angemoniaque-dev / ange-dev-* | angemoniaque-prod / ange-prod-* |
| Jeu | http://localhost:8080 | http://localhost |
| PgAdmin / Postgres | :5051 / :5433 | :5050 / interne |
| Données | volume pgdata_dev | volume pgdata |
Ils peuvent tourner en même temps sans s'écraser. `cp .env.example .env` d'abord. Commandes : voir Makefile.
