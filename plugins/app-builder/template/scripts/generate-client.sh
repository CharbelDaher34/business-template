#!/usr/bin/env bash
# Regenerates the frontend's API client (frontend/src/client) from the running
# backend. Run it after any change to backend routes or schemas.
# Usage: ./scripts/generate-client.sh
#
# Never edit frontend/src/client by hand: this script overwrites it.
set -euo pipefail
cd "$(dirname "$0")/.."

running="$(docker compose ps --status running --services 2>/dev/null)"
for service in backend frontend; do
  if ! grep -qx "$service" <<<"$running"; then
    echo "The app is not running ($service is down). Start it with: docker compose up -d"
    exit 1
  fi
done

echo "Fetching the API description from the backend..."
docker compose exec -T frontend bun -e '
  const res = await fetch("http://backend:8000/api/v1/openapi.json")
  if (!res.ok) throw new Error(`The backend answered ${res.status}. Check: docker compose logs backend`)
  await Bun.write("openapi.json", await res.text())
'

echo "Generating the API client..."
docker compose exec -T frontend bun run generate-client
docker compose exec -T frontend rm -f openapi.json

echo "Done: frontend/src/client is up to date."
