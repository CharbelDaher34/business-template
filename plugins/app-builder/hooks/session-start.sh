#!/usr/bin/env bash
# app-builder: SessionStart hook. Whatever it prints is added to Claude's context
# at the start of every session (and after /clear or compaction).
#
# - Inside an app project (the folder, or its git root, has .app-builder.json):
#   prints the always-on rules (rules/app-rules.md) and a line about this app.
# - Anywhere else: prints one short line saying how to start a new app.
#
# Requires jq (preferred) or python3 to read the hook JSON.
set -uo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Print the value of a top-level key from the JSON on stdin.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$1" '.[$k] // empty | tostring'
  else
    python3 -c '
import json, sys
value = json.load(sys.stdin).get(sys.argv[1])
print("" if value is None else value if isinstance(value, str) else json.dumps(value))' "$1"
  fi
}

input="$(cat)"
cwd="$(json_get cwd <<<"$input" 2>/dev/null)"
[[ -n "$cwd" ]] || cwd="$PWD"

app_root=""
if [[ -f "$cwd/.app-builder.json" ]]; then
  app_root="$cwd"
else
  git_root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$git_root" && -f "$git_root/.app-builder.json" ]] && app_root="$git_root"
fi

if [[ -z "$app_root" ]]; then
  echo "app-builder plugin is installed. To start a new app, open Claude Code in an empty folder and run /app-builder:new-app."
  exit 0
fi

cat "$PLUGIN_DIR/rules/app-rules.md"
marker="$app_root/.app-builder.json"
name="$(json_get app_name <"$marker" 2>/dev/null)"
port="$(json_get app_port <"$marker" 2>/dev/null)"
echo
echo "This app: ${name:-"(name not set yet)"}, port ${port:-"(not picked yet)"}, folder $app_root."
echo "app-builder plugin files (references, template): $PLUGIN_DIR"
