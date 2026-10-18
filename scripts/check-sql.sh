#!/bin/sh
# Applique les scripts SQL dans l'ordre sur une base vierge (CI + pre-commit si psql dispo).
set -e
export PGPASSWORD="${PGPASSWORD:-ange}"
H="-h ${PGHOST:-localhost} -U ${PGUSER:-ange} -d ${PGDATABASE:-angemoniaque} -v ON_ERROR_STOP=1 -q"
for f in db/*.sql; do psql $H -f "$f"; done
psql $H -c "SELECT count(*) AS specs FROM game_schema.specializations" 
