#!/usr/bin/env bash
# Run the php-fpm e2e test suite: the shipped image together with
# mwaeckerlin/nginx as FastCGI front end (PHP execution, front controller,
# HTTPS forwarding). nginx is a sibling project consumed as a prebuilt
# image — build it there first if you want to test against a local build.
# Usage: bash tests/run-e2e.sh [pytest-args...]
set -euo pipefail

COMPOSE="tests/e2e/docker-compose.yml"
cd "$(dirname "$0")/.."

cleanup() {
    docker compose -f "$COMPOSE" down -v --remove-orphans 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Building test stack..."
docker compose -f "$COMPOSE" build --quiet

echo "==> Starting services..."
docker compose -f "$COMPOSE" up -d --remove-orphans php-fpm nginx

echo "==> Running tests..."
EXIT=0
docker compose -f "$COMPOSE" run --rm test-runner "$@" || EXIT=$?

if [[ $EXIT -ne 0 ]]; then
    echo "==> Collecting logs on failure..."
    docker compose -f "$COMPOSE" logs 2>&1 | tail -120
fi

exit $EXIT
