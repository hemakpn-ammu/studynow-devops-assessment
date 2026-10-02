#!/bin/sh

set -e

NGINX_CONFIG="./docker/nginx/nginx.conf"
ACTIVE_FILE="./docker/nginx/active_backend"

if [ ! -f "$ACTIVE_FILE" ]; then
    echo "blue" > "$ACTIVE_FILE"
fi

ACTIVE=$(cat "$ACTIVE_FILE")

if [ "$ACTIVE" = "blue" ]; then
    CURRENT="blue"
    TARGET="green"
else
    CURRENT="green"
    TARGET="blue"
fi

echo "Current backend: $CURRENT"
echo "Target backend: $TARGET"

echo "Building and starting $TARGET application..."

docker compose build "app_$TARGET"
docker compose up -d "app_$TARGET"

echo "Waiting for $TARGET to become healthy..."

for i in $(seq 1 30); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "studynow-app-$TARGET" 2>/dev/null || true)

    if [ "$STATUS" = "healthy" ]; then
        echo "$TARGET application is healthy."
        break
    fi

    if [ "$STATUS" = "unhealthy" ]; then
        echo "ERROR: $TARGET application became unhealthy."
        exit 1
    fi

    sleep 2
done

STATUS=$(docker inspect --format='{{.State.Health.Status}}' "studynow-app-$TARGET" 2>/dev/null || true)

if [ "$STATUS" != "healthy" ]; then
    echo "ERROR: $TARGET application did not become healthy."
    exit 1
fi

echo "Switching Nginx from $CURRENT to $TARGET..."

sed -i "s/server app_${CURRENT}:3000;/server app_${TARGET}:3000;/" "$NGINX_CONFIG"

docker exec studynow-nginx nginx -t

docker exec studynow-nginx nginx -s reload

echo "$TARGET" > "$ACTIVE_FILE"

echo "Verifying application through Nginx..."

if curl -fsS http://localhost:8080/health > /dev/null; then
    echo "Deployment successful."
    echo "Active backend: $TARGET"
else
    echo "ERROR: Public health check failed."
    echo "Restoring Nginx to $CURRENT..."

    sed -i "s/server app_${TARGET}:3000;/server app_${CURRENT}:3000;/" "$NGINX_CONFIG"

    docker exec studynow-nginx nginx -t
    docker exec studynow-nginx nginx -s reload

    echo "$CURRENT" > "$ACTIVE_FILE"

    exit 1
fi