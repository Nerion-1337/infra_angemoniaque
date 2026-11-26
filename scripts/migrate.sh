#!/bin/sh
# Migration catch-up : applique les infra/db/*.sql manquants (ordre lexicographique),
# quel que soit l'état du volume Postgres.
#
# - Volume vierge   : l'entrypoint Postgres a déjà appliqué tous les fichiers ; le script
#   fait le « baseline » — reconnaît chaque fichier via son marqueur (artefact distinctif)
#   et les enregistre dans game_schema.schema_migrations SANS les rejouer.
# - Volume historique : l'entrypoint ne s'exécute pas (volume non vide) ; les fichiers
#   dont le marqueur est absent sont appliqués un par un, dans l'ordre, puis enregistrés.
#
# Limites documentées : un fichier appliqué à moitié (crash en cours de fichier) doit être
# réparé à la main ; une seule instance migrateur par volume (le service compose).
#
# Usage : sh scripts/migrate.sh
# Env : PGHOST (postgres), POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, MIGRATIONS_DIR (db)
set -e
export PGPASSWORD="${POSTGRES_PASSWORD:-ange}"
PGH="${PGHOST:-postgres}"; PGU="${POSTGRES_USER:-ange}"; PGD="${POSTGRES_DB:-angemoniaque}"
MIGRATIONS="${MIGRATIONS_DIR:-db}"
PSQL() { psql -h "$PGH" -U "$PGU" -d "$PGD" "$@"; }
# Garde-fou : jamais de no-op silencieux si le répertoire de migrations est absent.
[ -n "$(ls "$MIGRATIONS"/*.sql 2>/dev/null)" ] || { echo "ERREUR : aucun fichier .sql dans '$MIGRATIONS' (variable MIGRATIONS_DIR ?)" >&2; exit 1; }

# Attend que Postgres accepte les connexions (volume vierge : initdb de l'entrypoint d'abord).
until psql -h "$PGH" -U "$PGU" -d "$PGD" -c "SELECT 1" >/dev/null 2>&1; do sleep 2; done

# Table de suivi dans game_schema (l'espace public, lui, est vide).
PSQL -q -v ON_ERROR_STOP=1 -c "CREATE SCHEMA IF NOT EXISTS game_schema;
CREATE TABLE IF NOT EXISTS game_schema.schema_migrations (
  name TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);"

# Marqueurs : « l'effet du fichier F est-il déjà dans la base ? » (baseline 1re exécution).
# t → le fichier a déjà tourné (volume historiquement migré) ; on ne le rejoue jamais.
marker() {
  case "$1" in
    01_init.sql)        echo "SELECT to_regclass('game_schema.specializations') IS NOT NULL";;
    02_extra.sql)       echo "SELECT to_regclass('game_schema.accounts') IS NOT NULL";;
    03_features.sql)    echo "SELECT to_regclass('game_schema.summons') IS NOT NULL";;
    04_guild_order.sql) echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='guild_folders' AND c.column_name='sort_order')";;
    05_rank_order.sql)  echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='guild_ranks' AND c.column_name='sort_order')";;
    06_default_rank.sql) echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='guilds' AND c.column_name='default_rank_id')";;
    07_forum_perms.sql)  echo "SELECT to_regclass('game_schema.guild_topic_reads') IS NOT NULL";;
    08_world.sql)       echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='characters' AND c.column_name='burn_until')";;
    09_world2.sql)      echo "SELECT EXISTS (SELECT 1 FROM game_schema.maps m WHERE m.id=2 AND m.width=300 AND m.height=300)";;
    10_admin.sql)       echo "SELECT to_regclass('game_schema.races') IS NOT NULL";;
    11_bestiaire.sql)   echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='spawn_rules' AND c.column_name='active')";;
    12_monstre_details.sql) echo "SELECT to_regclass('game_schema.monster_spells') IS NOT NULL";;
    13_monstre_capacites.sql) echo "SELECT to_regclass('game_schema.monster_auras') IS NULL";;
    14_rarete_acquisition.sql) echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c JOIN information_schema.tables t ON t.table_name=c.table_name AND t.table_schema='game_schema' WHERE c.table_name='spells' AND c.column_name='usable_by')";;
    43_invocations_montees.sql) echo "SELECT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='game_schema' AND c.table_name='characters' AND c.column_name='riding_summon_id')";;
    *)                  echo "SELECT false";;  # nouveau fichier : pas de marqueur, appliqué s'il manque
  esac
}

# Volume NEUF : l'entrypoint Postgres vient de jouer TOUS les fichiers (journal vide + effet du 43 présent). On les enregistre
# tous sans rien rejouer : rejouer un ancien fichier après le 43 (qui supprime les montures) échouerait.
FRESH=no
if [ "$(PSQL -tAc "SELECT count(*) FROM game_schema.schema_migrations")" = "0" ] && [ "$(PSQL -tAc "$(marker 43_invocations_montees.sql)")" = "t" ]; then FRESH=yes; fi

for f in "$MIGRATIONS"/*.sql; do
  n=$(basename "$f")
  case "$n" in [0-9][0-9]_*.sql) ;; *) continue ;; esac   # tous les NN_*.sql (avant : 0*|1* seulement, 20+ ignorés)
  if [ "$(PSQL -tAc "SELECT count(*) FROM game_schema.schema_migrations WHERE name='$n'")" = "1" ]; then
    echo "ok (applied) $n"
    continue
  fi
  if [ "$FRESH" = "yes" ]; then mres=t; else mres=$(PSQL -tAc "$(marker "$n")"); fi
  if [ "$mres" = "t" ]; then
    echo "ok (marker)  $n — baseline"
    PSQL -q -v ON_ERROR_STOP=1 -c "INSERT INTO game_schema.schema_migrations (name) VALUES ('$n');"
    continue
  fi
  echo "apply        $n"
  PSQL -q -v ON_ERROR_STOP=1 -f "$f"
  PSQL -q -v ON_ERROR_STOP=1 -c "INSERT INTO game_schema.schema_migrations (name) VALUES ('$n');"
done
echo "Migrations : OK"
