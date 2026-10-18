#!/usr/bin/env bash
# Sauvegarde SQL (reprise du dépôt d'origine). Usage : ./backup-db.sh [dev|prod]
set -euo pipefail
ENV="${1:-dev}"; FILE="backup_angemoniaque_${ENV}_$(date +%Y%m%d_%H%M%S).sql"
docker exec -t "ange-${ENV}-postgres" pg_dump -U "${POSTGRES_USER:-ange}" -d "${POSTGRES_DB:-angemoniaque}" > "$FILE"
echo "Dump SQL créé avec succès : $FILE"
