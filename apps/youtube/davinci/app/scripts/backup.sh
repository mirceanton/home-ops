#!/bin/bash
set -euo pipefail

BACKUP_FILE="${BACKUP_DIR}/davinci-$(date +%Y%m%d-%H%M%S).sql.gz"
echo "Starting backup to ${BACKUP_FILE}..."

PGPASSWORD="${PGPASSWORD}" pg_dump \
  --host="${PGHOST}" \
  --port="${PGPORT}" \
  --username="${PGUSER}" \
  --dbname="${PGDATABASE}" \
  --format=custom \
  --compress=6 \
  --no-owner \
  --no-acl \
  > "${BACKUP_FILE}"

echo "Backup completed: ${BACKUP_FILE}"

# Keep only the last 7 backups
ls -t "${BACKUP_DIR}"/davinci-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
echo "Cleanup completed. Remaining backups:"
ls -la "${BACKUP_DIR}"/davinci-*.sql.gz 2>/dev/null || echo "No backups found"
