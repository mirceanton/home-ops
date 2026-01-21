#!/bin/bash
set -euo pipefail

BACKUP_FILE="${BACKUP_DIR}/booklore-$(date +%Y%m%d-%H%M%S).sql.gz"
echo "Starting backup to ${BACKUP_FILE}..."

mariadb-dump \
  --host="${MARIADB_HOST}" \
  --port="${MARIADB_PORT}" \
  --user="${MARIADB_USER}" \
  --password="${MARIADB_PASSWORD}" \
  --single-transaction \
  --routines \
  --triggers \
  --databases "${MARIADB_DATABASE}" \
  | gzip > "${BACKUP_FILE}"

echo "Backup completed: ${BACKUP_FILE}"

# Keep only the last 7 backups
ls -t "${BACKUP_DIR}"/booklore-*.sql.gz | tail -n +8 | xargs -r rm -f
echo "Cleanup completed. Remaining backups:"
ls -la "${BACKUP_DIR}"/booklore-*.sql.gz
