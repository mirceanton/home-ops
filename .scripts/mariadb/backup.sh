#!/bin/bash
set -euo pipefail

mkdir -p "$${BACKUP_DIR}"

BACKUP_FILE="$${BACKUP_DIR}/$${APP_NAME}-$(date +%Y%m%d-%H%M%S).sql.gz"
echo "Starting backup to $${BACKUP_FILE}..."

mariadb-dump \
  --host="$${MARIADB_HOST}" \
  --port="$${MARIADB_PORT}" \
  --user="$${MARIADB_USER}" \
  --password="$${MARIADB_PASSWORD}" \
  --single-transaction \
  --routines \
  --triggers \
  --databases "$${MARIADB_DATABASE}" \
  | gzip > "$${BACKUP_FILE}"

echo "Backup completed: $${BACKUP_FILE}"

# Keep only the last 7 backups
ls -t "$${BACKUP_DIR}"/$${APP_NAME}-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
echo "Cleanup completed. Remaining backups:"
ls -la "$${BACKUP_DIR}"/$${APP_NAME}-*.sql.gz 2>/dev/null || echo "No backups found"
