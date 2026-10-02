#!/bin/sh

set -e

if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi

HEALTH_URL="http://localhost:8080/health"

echo "Checking StudyNow application health..."

if curl -fsS "$HEALTH_URL" > /dev/null; then
    echo "Application health check: HEALTHY"
    exit 0
fi

echo "Application health check: FAILED"

if [ -z "$ALERT_WEBHOOK_URL" ]; then
    echo "WARNING: ALERT_WEBHOOK_URL is not configured."
    exit 1
fi

echo "Sending alert notification..."

curl -fsS \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"content":"🚨 StudyNow alert: application health check failed at http://localhost:8080/health"}' \
    "$ALERT_WEBHOOK_URL"

echo "Alert notification sent."
exit 1