# Graph Report - infra  (2026-11-25)

## Corpus Check
- 39 files · ~9,978 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 7 file(s) not represented in the graph (top: (none) 5, .conf 2)

## Summary
- 224 nodes · 230 edges · 18 communities (15 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2f177cd7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- services
- services
- services
- postgres
- with
- migrator
- postgres
- backend
- migrator
- postgres
- frontend
- backend
- backend
- AGENTS.md — ia_agent / infra
- migrate.sh
- check-sql.sh
- README.md
- backup-db.sh

## God Nodes (most connected - your core abstractions)
1. `backend` - 9 edges
2. `services` - 9 edges
3. `services` - 8 edges
4. `migrator` - 8 edges
5. `migrator` - 8 edges
6. `services` - 8 edges
7. `postgres` - 7 edges
8. `frontend` - 7 edges
9. `backend` - 7 edges
10. `nginx` - 6 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (18 total, 3 thin omitted)

### Community 0 - "services"
Cohesion: 0.07
Nodes (31): build, depends_on, interval, retries, test, depends_on, image, ports (+23 more)

### Community 1 - "services"
Cohesion: 0.09
Nodes (21): name, container_name, depends_on, image, ports, volumes, container_name, env_file (+13 more)

### Community 2 - "services"
Cohesion: 0.11
Nodes (17): name, container_name, depends_on, image, ports, volumes, container_name, env_file (+9 more)

### Community 3 - "postgres"
Cohesion: 0.11
Nodes (17): POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_USER, jobs, validate, name, on, env (+9 more)

### Community 4 - "with"
Cohesion: 0.13
Nodes (14): runs-on, steps, jobs, deploy, name, on, push, tags (+6 more)

### Community 5 - "migrator"
Cohesion: 0.14
Nodes (14): depends_on, postgres, redis, PGHOST, command, container_name, depends_on, env_file (+6 more)

### Community 6 - "postgres"
Cohesion: 0.16
Nodes (14): interval, retries, test, container_name, env_file, healthcheck, image, ports (+6 more)

### Community 7 - "backend"
Cohesion: 0.14
Nodes (14): build, container_name, env_file, environment, image, context, DATABASE_URL, REDIS_URL (+6 more)

### Community 8 - "migrator"
Cohesion: 0.14
Nodes (14): depends_on, postgres, redis, PGHOST, command, container_name, depends_on, env_file (+6 more)

### Community 9 - "postgres"
Cohesion: 0.18
Nodes (13): interval, retries, test, container_name, env_file, healthcheck, image, volumes (+5 more)

### Community 10 - "frontend"
Cohesion: 0.18
Nodes (12): build, context, target, API_URL, CHOKIDAR_USEPOLLING, build, container_name, depends_on (+4 more)

### Community 11 - "backend"
Cohesion: 0.18
Nodes (11): build, depends_on, env_file, environment, postgres, redis, DATABASE_URL, REDIS_URL (+3 more)

### Community 12 - "backend"
Cohesion: 0.22
Nodes (9): container_name, env_file, environment, image, ports, volumes, DATABASE_URL, REDIS_URL (+1 more)

### Community 13 - "AGENTS.md — ia_agent / infra"
Cohesion: 0.33
Nodes (5): AGENTS.md — ia_agent / infra, Interfaces avec les autres dépôts, Rôle de ce dépôt, Stack et commandes, Travail dans ce dépôt

### Community 14 - "migrate.sh"
Cohesion: 0.60
Nodes (4): marker(), PGPASSWORD, PSQL(), migrate.sh script

## Knowledge Gaps
- **2 isolated node(s):** `PGPASSWORD`, `PGPASSWORD`
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 134 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `services` connect `services` to `frontend`, `backend`, `migrator`, `postgres`?**
  _High betweenness centrality (0.071) - this node is a cross-community bridge._
- **What connects `PGPASSWORD`, `PGPASSWORD` to the rest of the system?**
  _2 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.06854838709677419 - nodes in this community are weakly interconnected._
- **Why does `services` connect `services` to `migrator`, `postgres`, `backend`?**
  _High betweenness centrality (0.065) - this node is a cross-community bridge._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.09090909090909091 - nodes in this community are weakly interconnected._
- **Why does `backend` connect `backend` to `services`, `frontend`, `migrator`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Should `services` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._