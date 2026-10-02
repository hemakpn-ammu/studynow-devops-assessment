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
OFFSITE_DIR="./backups/offsite-backups"
KEY_FILE="./.secrets/backup-key.txt"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DUMP_FILE="${BACKUP_DIR}/mongodb_${TIMESTAMP}.archive.gz"
ENCRYPTED_FILE="${DUMP_FILE}.age"

mkdir -p "$BACKUP_DIR"
mkdir -p "$OFFSITE_DIR"

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: age private key not found: $KEY_FILE"
    exit 1
fi

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
  --gzip > "$DUMP_FILE"

echo "MongoDB dump created:"
echo "$DUMP_FILE"

echo "Encrypting backup with age..."

RECIPIENT=$(age-keygen -y "$KEY_FILE")

age --recipient "$RECIPIENT" \
    --output "$ENCRYPTED_FILE" \
    "$DUMP_FILE"

rm -f "$DUMP_FILE"

echo "Encrypted backup created:"
echo "$ENCRYPTED_FILE"

echo "Shipping encrypted backup to simulated off-provider location..."

cp "$ENCRYPTED_FILE" "$OFFSITE_DIR/"

echo "Offsite backup created:"
echo "$OFFSITE_DIR/$(basename "$ENCRYPTED_FILE")"

echo "Backup completed successfully."