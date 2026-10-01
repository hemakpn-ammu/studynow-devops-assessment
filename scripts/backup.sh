#!/bin/sh

set -e

# Load local environment variables
if [ -f .env ]; then
    set -a
    . ./.env
    set +a
else
    echo "ERROR: .env file not found"
    exit 1
fi

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/mongodb_${TIMESTAMP}.archive.gz"

mkdir -p "$BACKUP_DIR"

echo "Starting MongoDB backup..."

docker exec \
  -e MONGO_APP_USERNAME="$MONGO_APP_USERNAME" \
  -e MONGO_APP_PASSWORD="$MONGO_APP_PASSWORD" \
  studynow-mongo \
  mongodump \
  --username="$MONGO_APP_USERNAME" \
  --password="$MONGO_APP_PASSWORD" \
  --authenticationDatabase=studynow \
  --db=studynow \
  --archive \
  --gzip > "$BACKUP_FILE"

echo "MongoDB backup created:"
echo "$BACKUP_FILE"