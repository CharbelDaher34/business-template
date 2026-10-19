#!/usr/bin/env bash
# DELETES ALL DATA in this app's database, then starts the app again so the
# migrations and seed data run on a fresh, empty database.
# Usage: ./scripts/reset-db.sh --yes
#
# Only touches THIS app (this folder's compose project and its db volume).
# Refuses to run when the data is marked as real (DATA_IS_REAL=true in .env,
# or "data_is_real": true in .app-builder.json).
set -euo pipefail
cd "$(dirname "$0")/.."

# Print the value at a key path of the JSON on stdin (jq, or python3 without jq).
# Example: json_get volumes db-data name < file.json
json_get() {
  if command -v jq >/dev/null 2>&1; then
    jq -r 'getpath($ARGS.positional) | if . == null then "null" else tostring end' --args "$@"
  else
    python3 -c '
import json, sys
value = json.load(sys.stdin)
for key in sys.argv[1:]:
    value = value.get(key) if isinstance(value, dict) else None
print(value if isinstance(value, str) else json.dumps(value))' "$@"
  fi
}

if grep -Eqi '^[[:space:]]*DATA_IS_REAL[[:space:]]*=[[:space:]]*"?true' .env 2>/dev/null ||
  { [[ -f .app-builder.json ]] && [[ "$(json_get data_is_real <.app-builder.json)" == "true" ]]; }; then
  echo "REFUSED: this app's data is marked as real (DATA_IS_REAL / data_is_real)."
  echo "Real data is never wiped. Change the database with a migration instead."
  exit 1
fi

if [[ "${1:-}" != "--yes" ]]; then
  echo "WARNING: this deletes ALL data in this app's database (every user and record)."
  echo "The app restarts with only the seed data (first admin and demo rows)."
  echo "Other apps on this server are not affected."
  echo
  echo "Only run it after the app owner agreed. To go ahead: ./scripts/reset-db.sh --yes"
  exit 1
fi

volume="$(docker compose config --format json | json_get volumes db-data name)"
if [[ -z "$volume" || "$volume" == "null" ]]; then
  echo "Could not find this app's database volume in compose.yml. Nothing was deleted."
  exit 1
fi

echo "Stopping this app..."
docker compose down
if docker volume inspect "$volume" >/dev/null 2>&1; then
  echo "Deleting this app's database volume ($volume)..."
  docker volume rm "$volume" >/dev/null
fi
echo "Starting the app again (migrations and seed data run now)..."
docker compose up -d
echo "Done: the database was reset."
