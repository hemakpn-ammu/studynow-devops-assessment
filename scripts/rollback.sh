#!/bin/sh

set -e

NGINX_CONFIG="./docker/nginx/nginx.conf"
ACTIVE_FILE="./docker/nginx/active_backend"

if [ ! -f "$ACTIVE_FILE" ]; then
    echo "ERROR: active backend state file not found."
    exit 1
fi

ACTIVE=$(cat "$ACTIVE_FILE")

if [ "$ACTIVE" = "blue" ]; then
    TARGET="green"
else
    TARGET="blue"
fi

echo "Current backend: $ACTIVE"
echo "Rollback target: $TARGET"

TARGET_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "studynow-app-$TARGET" 2>/dev/null || true)

if [ "$TARGET_STATUS" != "healthy" ]; then
    echo "ERROR: rollback target app_$TARGET is not healthy."
    exit 1
fi

echo "Rollback target app_$TARGET is healthy."

echo "Switching Nginx from $ACTIVE to $TARGET..."

sed -i "s/server app_${ACTIVE}:3000;/server app_${TARGET}:3000;/" "$NGINX_CONFIG"

docker exec studynow-nginx nginx -t

docker exec studynow-nginx nginx -s reload

echo "$TARGET" > "$ACTIVE_FILE"

echo "Verifying application through Nginx..."

if curl -fsS http://localhost:8080/health > /dev/null; then
    echo "Rollback successful."
    echo "Active backend: $TARGET"
else
    echo "ERROR: Rollback health check failed."
    exit 1
fi