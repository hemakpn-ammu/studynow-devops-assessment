#!/bin/sh

set -e

BACKUP_FILE="$1"
KEY_FILE="./.secrets/backup-key.txt"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./scripts/restore.sh <encrypted-backup-file>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: backup file not found: $BACKUP_FILE"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: age private key not found: $KEY_FILE"
    exit 1
fi

if [ -f .env ]; then
    set -a
    . ./.env
    set +a
else
    echo "ERROR: .env file not found"
    exit 1
fi

TEMP_DUMP="./restore-test/mongodb_restore.archive.gz"

mkdir -p ./restore-test

echo "Decrypting backup..."

age \
    --decrypt \
    --identity "$KEY_FILE" \
    --output "$TEMP_DUMP" \
    "$BACKUP_FILE"

echo "Restoring MongoDB database..."

docker exec \
  -e MONGO_APP_USERNAME="$MONGO_APP_USERNAME" \
  -e MONGO_APP_PASSWORD="$MONGO_APP_PASSWORD" \
  studynow-mongo \
  mongorestore \
  --username="$MONGO_APP_USERNAME" \
  --password="$MONGO_APP_PASSWORD" \
  --authenticationDatabase=studynow \
  --db=studynow \
  --archive \
  --gzip \
  --drop < "$TEMP_DUMP"

rm -f "$TEMP_DUMP"

echo "Verifying application health..."

if curl -fsS http://localhost:8080/health > /dev/null; then
    echo "Restore completed successfully."
    echo "Application health check: healthy"
else
    echo "ERROR: application health check failed after restore."
    exit 1
fi