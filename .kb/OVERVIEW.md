# Project overview
_Généré par `kb overview` — ne pas éditer ici ; notes manuelles dans `.kb/NOTES.md`._

# Project notes (maintenus à la main / par l'agent)

## Stack & conventions
- Docker Compose 3 fichiers : base, `dev` (projet `angemoniaque-dev`, ports 8080/5433/5051, sources bind-mountées, node_modules en volumes nommés), `prod` (projet `angemoniaque-prod`, ports 80/5050/9000)
- Nginx : `/` → front (dist statique en prod, Vite:5173 en dev), `/api/` → back:3000 (prefix stripé, upgrade WS)
- Migrations `db/*.sql` en ordre lexicographique, appliquées uniquement sur volume vide ; changements de schéma = `make dev-reset` (dev)
- Règle absolue : ne JAMAIS modifier `../front` ou `../back` depuis ce dépôt — documenter et signaler
- Secrets dans `.env` (jamais commité) ; `.env.example` = template

## Commandes utiles
- dev : `make dev-up` (jeu sur http://localhost:8080) ; prod : `make prod-up` (http://localhost)
- validation locale (sans docker/psql) : `bash -n scripts/*.sh` + parsing YAML des 3 compose (`kb` test_cmd)
- tests SQL (psql requis) : `scripts/check-sql.sh` ; backup : `scripts/backup-db.sh [dev|prod]`
- kb : backend d'embedding `hash` (offline) dans `.kb/config.json`

## Features (17)
- **building-activation-schema** [done] (.kb/cards/building-activation-schema.md) Migration 28 : conditions d activation des bâtiments — Migration 28 : conditions d'activation de la capacité d'un bâtiment. — files: db/28_activation_batiments.sql
- **buildings-schema** [done] (.kb/cards/buildings-schema.md) Migration 22 : bâtiments paramétrables et unicité des cases séparée — Migration 22 : colonnes des bâtiments paramétrables et séparation de l'unicité des cases (entités / bâtiments). — files: db/22_batiments.sql
- **deposits-schema** [done] (.kb/cards/deposits-schema.md) Migrations 23, 30, 31 : secteurs de ressources, leurs ressources, conditions de récolte — Migrations 23 et 30 : secteurs de ressources (zone d'un monde) et leurs ressources. — files: db/23_gisements.sql, db/30_secteurs_ressources.sql, db/31_conditions_recolte.sql, db/33_sac_ressources.sql
- **divine-families-schema** [done] (.kb/cards/divine-families-schema.md) Familles divines (migration 16) : divine_families, items.divine_family, divine_items.item_id — Migration 16 : objets divins gérés comme les autres objets (ligne `items` de rareté divin) et familles libres au-delà de relique / arcane / artefact, chacune avec un plafond d'exemplaires. — files: db/16_familles_divines.sql
- **docker-infrastructure** [done] (.kb/cards/docker-infrastructure.md) Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations — Orchestration Docker du projet : environnements dev et prod indépendants (Postgres 16, Redis 7, backend, frontend, Nginx, outils), migrations SQL ordonnées du schéma `game_schema`, scripts d'exploitat — files: docker-compose.yml, docker-compose.dev.yml, docker-compose.prod.yml, nginx/nginx.conf (+12)
- **item-stats-schema** [done] (.kb/cards/item-stats-schema.md) Migration 26 : bonus de caractéristiques des objets (trigger trg_item_bonus), armure magique de base — Migration 26 : bonus de caractéristiques des objets reportés sur la fiche du personnage, armure magique de base, bonus d'armure magique pour l'occupant d'un bâtiment. — files: db/36_portee_armes.sql, db/26_objets_caracteristiques.sql, db/32_equipement_carte.sql, db/34_taille_coffre.sql
- **monster-mounts-schema** [done] (.kb/cards/monster-mounts-schema.md) Migration 25 : monstres servant de monture (projection mounts, trigger sync_mount) — Migration 25 : fusion monstres / montures. — files: db/35_xp_reapparition.sql, db/25_monstres_montures.sql
- **mount-call-schema** [done] (.kb/cards/mount-call-schema.md) Migration 29 : montures invocables à pied, équipement des montures — Migration 29 : identifiant des montures possédées, lien invocation → monture / type de monstre, équipement des montures, retour des PV et de l'énergie au renvoi. — files: db/29_montures_invocables.sql
- **races-clock-schema** [done] (.kb/cards/races-clock-schema.md) Migrations 17-18 : apparition, limites et équipement de départ par race, horloge du monde, trigger de création aligné — Migrations 17 et 18 : réglages des races (zone d'apparition, limites, équipement de départ), horloge du monde persistante, et trigger de création de personnage aligné sur ces réglages avec exemption d — files: db/17_races_apparition_horloge.sql, db/18_depart_par_race.sql
- **rank-up-schema** [done] (.kb/cards/rank-up-schema.md) Migrations 21 et 24 : passage de rang (deux voies), rang temporaire, réapparition des monstres — Migration 21 : conditions de passage par rang et rang temporaire en cours. — files: db/21_passage_de_rang.sql, db/24_rangs_respawn.sql
- **recipes-shop-schema** [done] (.kb/cards/recipes-shop-schema.md) Migration 19 : boutique par race et recettes de parchemins — Migration 19 : boutique de l'hôtel de ville par race (objets, sorts) et table des recettes de parchemins. — files: db/19_boutique_parchemins.sql
- **schema-migrations-catchup** [done] (.kb/cards/schema-migrations-catchup.md) Rattrapage des migrations sur volume existant (service migrator) — Rattrapage des migrations sur un volume Postgres déjà créé (dev/prod) : le service `migrator` applique les fichiers `db/*.sql` manquants à chaque `make dev-up` / `prod-up`, sans casser un volume parti — files: scripts/migrate.sh, docker-compose.dev.yml, docker-compose.prod.yml, Makefile (+3)
- **spell-engine-schema** [done] (.kb/cards/spell-engine-schema.md) Migration 20 : effets de sort, dégâts sur la durée, liens sort ↔ entités — Migration 20 : colonne des effets de sort, dégâts sur la durée en cours, liens sort ↔ objet / monture / bâtiment. — files: db/20_moteur_sorts.sql
- **spell-summon-schema** [done] (.kb/cards/spell-summon-schema.md) Migration 27 : modes des sorts liés (au coup porté, à l attaque reçue) et invocations temporaires — Migration 27 : modes d'application des sorts liés à un élément et suivi des invocations temporaires. — files: db/27_invocations_liens.sql
- **tile-types-schema** [done] (.kb/cards/tile-types-schema.md) Table tile_types (migration 15) : types de case par monde — Table `tile_types` (migration 15) : un type de case par (monde, kind) avec nom, description, coût d'énergie et sort passif, éditée par la section admin « Cases ». — files: db/15_types_de_case.sql
- **world-schema** [done] (.kb/cards/world-schema.md) World schema: maps, positions (entity placement), character resources JSONB — Socle du schéma PostgreSQL (`01_init.sql`, `02_extra.sql`) et migrations de fonctionnalités qui suivent (guildes, forum, monde v2, admin, bestiaire, rareté…), lus par le back ; leur ordre fait partie  — files: db/01_init.sql, db/02_extra.sql, db/08_world.sql
- **world2-angel-demon** [done] (.kb/cards/world2-angel-demon.md) Monde Anges & Démons : migration 09_world2.sql (carte 300x300) — Adapte la base au monde 2 (Anges & Démons) : taille de la carte, capitales, portes, arrivées des portails humains, gardiens divins. — files: db/09_world2.sql

## File map
- `db/01_init.sql`
- `db/02_extra.sql`
- `db/03_features.sql`
- `db/04_guild_order.sql`
- `db/05_rank_order.sql`
- `db/06_default_rank.sql`
- `db/07_forum_perms.sql`
- `db/08_world.sql`
- `db/09_world2.sql`
- `db/10_admin.sql`
- `db/11_bestiaire.sql`
- `db/12_monstre_details.sql`
- `db/13_monstre_capacites.sql`
- `db/14_rarete_acquisition.sql`
- `db/15_types_de_case.sql`
- `db/16_familles_divines.sql`
- `db/17_races_apparition_horloge.sql`
- `db/18_depart_par_race.sql`
- `db/19_boutique_parchemins.sql`
- `db/20_moteur_sorts.sql`
- `db/21_passage_de_rang.sql`
- `db/22_batiments.sql`
- `db/23_gisements.sql`
- `db/24_rangs_respawn.sql`
- `db/25_monstres_montures.sql`
- `db/26_objets_caracteristiques.sql`
- `db/27_invocations_liens.sql`
- `db/28_activation_batiments.sql`
- `db/29_montures_invocables.sql`
- `db/30_secteurs_ressources.sql`
- `db/31_conditions_recolte.sql`
- `db/32_equipement_carte.sql`
- `db/33_sac_ressources.sql`
- `db/34_taille_coffre.sql`
- `db/35_xp_reapparition.sql`
- `db/36_portee_armes.sql`
- `docker-compose.dev.yml` — DEV — projet "angemoniaque-dev" : conteneurs ange-dev-*, base/volumes/réseau séparés de la prod, ports différe
- `docker-compose.prod.yml` — PROD — projet "angemoniaque-prod" : conteneurs ange-prod-*, volumes et réseau propres, images :prod
- `docker-compose.yml` — Dépôt infra : orchestre TOUT (db, cache, back, front, proxy, outils). Les dépôts backend/ et frontend/ sont cl
- `scripts/backup-db.sh` — Sauvegarde SQL (reprise du dépôt d'origine). Usage : ./backup-db.sh [dev|prod]
- `scripts/check-sql.sh` — Applique les scripts SQL dans l'ordre sur une base vierge (CI + pre-commit si psql dispo).
- `scripts/migrate.sh` — Migration catch-up : applique les infra/db/*.sql manquants (ordre lexicographique),
