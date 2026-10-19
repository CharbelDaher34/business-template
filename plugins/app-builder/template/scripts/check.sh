#!/usr/bin/env bash
# Runs every automatic check on this app. Claude runs it before saying a
# milestone is done. Usage: ./scripts/check.sh
#
# Checks: backend lint + formatting (ruff), backend smoke tests (pytest),
# frontend lint (Biome), frontend type check + build (tsc, vite).
# Everything runs inside this app's own containers, which must be running.
set -uo pipefail
cd "$(dirname "$0")/.."

running="$(docker compose ps --status running --services 2>/dev/null)"
for service in backend frontend; do
  if ! grep -qx "$service" <<<"$running"; then
    echo "The app is not running ($service is down). Start it with: docker compose up -d"
    exit 1
  fi
done

failed=()
step() {
  local name="$1"
  shift
  echo
  echo "==> $name"
  if "$@"; then
    echo "    OK: $name"
  else
    echo "    FAILED: $name"
    failed+=("$name")
  fi
}

step "Backend code style (ruff check)" docker compose exec -T backend ruff check app
step "Backend formatting (ruff format)" docker compose exec -T backend ruff format --check app
step "Backend smoke tests (pytest)" docker compose exec -T backend pytest -q
step "Frontend code style (Biome)" docker compose exec -T frontend bun run check
step "Frontend type check and build (tsc + vite)" docker compose exec -T frontend bun run build

echo
if ((${#failed[@]})); then
  echo "Some checks FAILED:"
  printf '  - %s\n' "${failed[@]}"
  echo "Fix these before calling the work done."
  exit 1
fi
echo "All checks passed."
