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

## Features (22)
- **building-activation-schema** [done] (.kb/cards/building-activation-schema.md) Migration 28 : conditions d activation des bâtiments — Migration 28 : conditions d'activation de la capacité d'un bâtiment. — files: db/28_activation_batiments.sql
- **buildings-schema** [done] (.kb/cards/buildings-schema.md) Migration 22 : bâtiments paramétrables et unicité des cases séparée — Migration 22 : colonnes des bâtiments paramétrables et séparation de l'unicité des cases (entités / bâtiments). — files: db/22_batiments.sql
- **creature-look-schema** [done] (.kb/cards/creature-look-schema.md) Migration 41 : design 3D et icône des types de monstres — Design 3D et icône d'un type de monstre (admin « Monstres »). — files: db/41_designs_icones.sql
- **deposits-schema** [done] (.kb/cards/deposits-schema.md) Migrations 23, 30, 31 : secteurs de ressources, leurs ressources, conditions de récolte — Migrations 23 et 30 : secteurs de ressources (zone d'un monde) et leurs ressources. — files: db/23_gisements.sql, db/30_secteurs_ressources.sql, db/31_conditions_recolte.sql, db/33_sac_ressources.sql
- **divine-energy-cost-schema** [done] (.kb/cards/divine-energy-cost-schema.md) Migration 42 : colonnes divine_energy_cost (sorts, recettes, cases) — Ajoute le coût en énergie divine, à côté du coût en énergie, aux sorts, recettes de parchemin et types de case. — files: db/42_energie_divine_couts.sql
- **divine-families-schema** [done] (.kb/cards/divine-families-schema.md) Familles divines (migration 16) : divine_families, items.divine_family, divine_items.item_id — Migration 16 : objets divins gérés comme les autres objets (ligne `items` de rareté divin) et familles libres au-delà de relique / arcane / artefact, chacune avec un plafond d'exemplaires. — files: db/16_familles_divines.sql
- **docker-infrastructure** [done] (.kb/cards/docker-infrastructure.md) Docker orchestration: dev/prod stacks, Nginx proxy, Postgres migrations — Orchestration Docker du projet : environnements dev et prod indépendants (Postgres 16, Redis 7, backend, frontend, Nginx, outils), migrations SQL ordonnées du schéma `game_schema`, scripts d'exploitat — files: docker-compose.yml, docker-compose.dev.yml, docker-compose.prod.yml, nginx/nginx.conf (+13)
- **faith-pact-schema** [done] (.kb/cards/faith-pact-schema.md) Migration 44 : compositions de pacte, pactes par rang, prières, réglages de la foi et des pactes — Schéma de la foi et des pactes réglés en admin. — files: db/44_foi_pactes.sql
- **forum-google-schema** [done] (.kb/cards/forum-google-schema.md) Migrations 38-40 : carte des ressources par monde, connexion Google, forum et pages légales — Schéma de la carte des ressources par monde (38), de la connexion Google (39), du forum public et des pages légales (40) ; en-têtes Nginx et réglages d'environnement associés. — files: db/38_carte_par_monde.sql, db/39_connexion_google.sql, db/40_forum_annonces.sql, nginx/nginx.conf (+3)
- **item-stats-schema** [done] (.kb/cards/item-stats-schema.md) Migration 26 : bonus de caractéristiques des objets (trigger trg_item_bonus), armure magique de base — Migration 26 : bonus de caractéristiques des objets reportés sur la fiche du personnage, armure magique de base, bonus d'armure magique pour l'occupant d'un bâtiment. — files: db/37_puissance_distance.sql, db/36_portee_armes.sql, db/26_objets_caracteristiques.sql, db/32_equipement_carte.sql (+1)
- **monster-mounts-schema** [done] (.kb/cards/monster-mounts-schema.md) Migration 25 : monstres servant de monture (projection mounts, trigger sync_mount) — **Historique : tables et triggers supprimés par la migration 43 (card `summon-ride-schema`).** Migration 25 : fusion monstres / montures. — files: db/35_xp_reapparition.sql, db/25_monstres_montures.sql
- **mount-call-schema** [done] (.kb/cards/mount-call-schema.md) Migration 29 : montures invocables à pied, équipement des montures — **Historique : tables et triggers supprimés par la migration 43 (card `summon-ride-schema`).** Migration 29 : identifiant des montures possédées, lien invocation → monture / type de monstre, équipemen — files: db/29_montures_invocables.sql
- **races-clock-schema** [done] (.kb/cards/races-clock-schema.md) Migrations 17-18 : apparition, limites et équipement de départ par race, horloge du monde, trigger de création aligné — Migrations 17 et 18 : réglages des races (zone d'apparition, limites, équipement de départ), horloge du monde persistante, et trigger de création de personnage aligné sur ces réglages avec exemption d — files: db/17_races_apparition_horloge.sql, db/18_depart_par_race.sql
- **rank-up-schema** [done] (.kb/cards/rank-up-schema.md) Migrations 21 et 24 : passage de rang (deux voies), rang temporaire, réapparition des monstres — Migration 21 : conditions de passage par rang et rang temporaire en cours. — files: db/21_passage_de_rang.sql, db/24_rangs_respawn.sql
- **recipes-shop-schema** [done] (.kb/cards/recipes-shop-schema.md) Migration 19 : boutique par race et recettes de parchemins — Migration 19 : boutique de l'hôtel de ville par race (objets, sorts) et table des recettes de parchemins. — files: db/19_boutique_parchemins.sql
- **schema-migrations-catchup** [done] (.kb/cards/schema-migrations-catchup.md) Rattrapage des migrations sur volume existant (service migrator) — Rattrapage des migrations sur un volume Postgres déjà créé (dev/prod) : le service `migrator` applique les fichiers `db/*.sql` manquants à chaque `make dev-up` / `prod-up`, sans casser un volume parti — files: scripts/migrate.sh, docker-compose.dev.yml, docker-compose.prod.yml, Makefile (+3)
- **spell-engine-schema** [done] (.kb/cards/spell-engine-schema.md) Migration 20 : effets de sort, dégâts sur la durée, liens sort ↔ entités — Migration 20 : colonne des effets de sort, dégâts sur la durée en cours, liens sort ↔ objet / bâtiment (les liens « monture » sont retirés par la migration 43). — files: db/20_moteur_sorts.sql
- **spell-summon-schema** [done] (.kb/cards/spell-summon-schema.md) Migration 27 : modes des sorts liés (au coup porté, à l attaque reçue) et invocations temporaires — Migration 27 : modes d'application des sorts liés à un élément et suivi des invocations temporaires. — files: db/27_invocations_liens.sql
- **summon-ride-schema** [done] (.kb/cards/summon-ride-schema.md) Migration 43 : fin des montures, monte des invocations, délais de relance ; migrateur sur volume neuf — Supprime tout ce qui touchait aux montures (décision de l'humain du 2026-11-26) et ajoute la monte d'une invocation et les délais de relance des sorts. — files: db/43_invocations_montees.sql, scripts/migrate.sh
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
- `db/37_puissance_distance.sql`
- `db/38_carte_par_monde.sql`
- `db/39_connexion_google.sql`
- `db/40_forum_annonces.sql`
- `db/41_designs_icones.sql`
- `db/42_energie_divine_couts.sql`
- `db/43_invocations_montees.sql`
- `db/44_foi_pactes.sql`
- `docker-compose.dev.yml` — DEV — projet "angemoniaque-dev" : conteneurs ange-dev-*, base/volumes/réseau séparés de la prod, ports différe
- `docker-compose.prod.yml` — PROD — projet "angemoniaque-prod" : conteneurs ange-prod-*, volumes et réseau propres, images :prod
- `docker-compose.yml` — Dépôt infra : orchestre TOUT (db, cache, back, front, proxy, outils). Les dépôts backend/ et frontend/ sont cl
- `graphify-out/.graphify_build_state.json`
- `graphify-out/.graphify_labels.json`
- `graphify-out/.graphify_labels.pending.json`
- `graphify-out/.graphify_partition_cache.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/7038b21dae983170b463a753fd932abe08c169c24af86d8311b753f160878a0b.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/8361eda8eac30f19124a29595ce4f2443ce277bd3167948c954f9c4263407a8d.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/896d0426aa9be7c7ee02f441e8e76e29cd0ab13d2c289a24cef69e521877de1f.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/94b0baaae158df7955f39babcd0d216dc9d2e6786d93f1ae88e8512403d7a16d.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/9c3a8c52a77e3dac5ebb22e4332d9743bd0e1a1db795f4b490947f557c229b50.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/a8c560e8a86e05c6701a5fb867e826295d258c841c9e3a5f02433c4fd52aa313.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/d04991803c26e96ba7d91b35120062db1f9e7bc1abe0267853047aaa364845d0.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/d92cdd4a66fbc5c2fbf4c12e5f9704ee32b451e6f6aa4f1b1cf11db28bc5ecf5.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/dd2b955f0b86f4c4807ffa256f9c55afc97e1583c27c894cf2259e15b13d68ec.json`
- `graphify-out/cache/ast/v0.9.118-s53-gd93bdf18e146/f0c0e72fcb5b4a3ceb3f349dfe717f7c2951dd5bd86f0c866982860599738a94.json`
- `graphify-out/cache/stat-index.json`
- `graphify-out/graph.html` — { box-sizing: border-box; margin: 0; padding: 0; }
- `graphify-out/graph.json`
- `graphify-out/manifest.json`
- `scripts/backup-db.sh` — Sauvegarde SQL (reprise du dépôt d'origine). Usage : ./backup-db.sh [dev|prod]
- `scripts/check-sql.sh` — Applique les scripts SQL dans l'ordre sur une base vierge (CI + pre-commit si psql dispo).
- `scripts/migrate.sh` — Migration catch-up : applique les infra/db/*.sql manquants (ordre lexicographique),
