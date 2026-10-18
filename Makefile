DEV = docker compose -f docker-compose.yml -f docker-compose.dev.yml
init:      ; test -f .env || cp .env.example .env
dev: init  ; $(DEV) up -d --build
prod: init ; docker compose up -d --build
logs:      ; $(DEV) logs -f backend frontend
test-back: ; docker build --target test ../backend
test-front:; docker build --target test ../frontend
test-int:  ; $(DEV) exec -e DATABASE_URL=postgres://$$POSTGRES_USER:$$POSTGRES_PASSWORD@postgres:5432/$$POSTGRES_DB -e REDIS_URL=redis://redis:6379 backend npx vitest run
psql:      ; $(DEV) exec postgres sh -c 'psql -U $$POSTGRES_USER $$POSTGRES_DB'
reset:     ; $(DEV) down -v
