#!/bin/bash
set -euo pipefail

# Find the latest backup if BACKUP_FILE is not specified
if [ -z "${BACKUP_FILE:-}" ]; then
  BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/${APP_NAME}-*.sql.gz 2>/dev/null | head -1)
  if [ -z "${BACKUP_FILE}" ]; then
    echo "ERROR: No backup files found in ${BACKUP_DIR}"
    exit 1
  fi
fi

echo "Restoring from: ${BACKUP_FILE}"
if [ ! -f "${BACKUP_FILE}" ]; then
  echo "ERROR: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "WARNING: This will restore the ${PGDATABASE} database!"
echo "Proceeding with restore..."

PGPASSWORD="${PGPASSWORD}" pg_restore \
  --host="${PGHOST}" \
  --port="${PGPORT}" \
  --username="${PGUSER}" \
  --dbname="${PGDATABASE}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  "${BACKUP_FILE}"

echo "Restore completed successfully from: ${BACKUP_FILE}"
