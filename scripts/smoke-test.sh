#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:5000}"

echo "Checking application health..."

curl --fail --silent --show-error \
  "$BASE_URL/health" |
  grep -q '"status":"healthy"'

echo "Smoke test passed."
