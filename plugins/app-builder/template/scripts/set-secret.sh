#!/usr/bin/env bash
# Saves one secret (an API key or a password) in .env, without it appearing on
# screen or in the chat with Claude. The app owner runs it in their own terminal.
# Usage: ./scripts/set-secret.sh NAME   (e.g. ./scripts/set-secret.sh ANTHROPIC_API_KEY)
set -euo pipefail
cd "$(dirname "$0")/.."

name="${1:-}"
if [[ ! "$name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
  echo "Usage: ./scripts/set-secret.sh NAME   (for example: ./scripts/set-secret.sh ANTHROPIC_API_KEY)"
  exit 1
fi
if [[ ! -t 0 ]]; then
  echo "Run this yourself in a terminal window, so the secret never passes through the chat."
  exit 1
fi
if [[ ! -f .env ]]; then
  echo "There is no .env file in this folder yet. Ask Claude to set up the app first."
  exit 1
fi

read -rsp "Paste or type $name (it won't be shown), then press Enter: " value
echo
if [[ -z "$value" ]]; then
  echo "Nothing was entered. .env was not changed."
  exit 1
fi
# These characters would need quoting in .env; API keys never contain them.
case "$value" in
  *[[:space:]\'\"\`\$\#\\]*)
    echo "Please don't use spaces or any of these characters: ' \" \` \$ # \\"
    echo ".env was not changed. Run the command again."
    exit 1
    ;;
esac
if [[ "$name" == *PASSWORD && ${#value} -lt 8 ]]; then
  echo "A password needs at least 8 characters. .env was not changed. Run the command again."
  exit 1
fi

# Replace the NAME= line if there is one, otherwise add it at the end.
tmp="$(mktemp .env.XXXXXX)"
found=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "$name="* ]]; then
    printf '%s=%s\n' "$name" "$value"
    found=1
  else
    printf '%s\n' "$line"
  fi
done <.env >"$tmp"
((found)) || printf '%s=%s\n' "$name" "$value" >>"$tmp"
chmod --reference=.env "$tmp"
mv "$tmp" .env

echo "Saved $name in .env. Go back to Claude and say it's done."
