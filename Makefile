DEV  = docker compose -f docker-compose.dev.yml
PROD = docker compose -f docker-compose.prod.yml
init:       ; test -f .env || cp .env.example .env
dev-up: init   ; $(DEV) up -d --build
dev-down:   ; $(DEV) down
dev-reset:  ; $(DEV) down -v
dev-logs:   ; $(DEV) logs -f backend frontend
dev-deps:   ; $(DEV) exec backend npm install && $(DEV) exec frontend npm install
test-back:  ; docker build --target test ../backend
test-front: ; docker build --target test ../frontend
test-int:   ; $(DEV) exec -e ADMIN_EMAIL=admin-test@ange.local backend npx vitest run
psql-dev:   ; $(DEV) exec postgres sh -c 'psql -U $$POSTGRES_USER $$POSTGRES_DB'
prod-up: init  ; $(PROD) up -d --build
prod-down:  ; $(PROD) down
prod-logs:  ; $(PROD) logs -f backend frontend
