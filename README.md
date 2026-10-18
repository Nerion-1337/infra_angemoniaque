# angemoniaque-infra
Prérequis : Docker + Docker Compose. Aucun Node/npm sur la machine.
    cd infra && cp .env.example .env
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build   # dev (hot reload)  -> http://localhost
    docker compose up -d --build                                                    # prod
Tests : `docker build --target test ../backend` / `../frontend` · Hooks : `git config core.hooksPath .githooks` dans chaque dépôt.
