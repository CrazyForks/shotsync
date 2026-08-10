#!/usr/bin/env bash
# One-shot deploy of the public read-only demo pool (worker `shotsync-demo`).
# Prereq: `npx wrangler login` once on this machine.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! CREATE_OUT=$(npx wrangler r2 bucket create shotsync-demo 2>&1); then
  if echo "$CREATE_OUT" | grep -qi "already exists"; then
    echo "bucket exists, ok"
  else
    echo "$CREATE_OUT" >&2
    exit 1
  fi
fi

TOKEN=$(openssl rand -hex 24)
printf '%s' "$TOKEN" | npx wrangler secret put AUTH_TOKEN --env demo

DEPLOY_OUT=$(npx wrangler deploy --env demo)
echo "$DEPLOY_OUT"
URL=$(echo "$DEPLOY_OUT" | grep -oE 'https://[a-zA-Z0-9.-]+\.workers\.dev' | head -1)

if [ -n "$URL" ]; then
  scripts/seed-demo.sh "$URL" "$TOKEN"
  echo
  echo "Demo pool live at: $URL"
  echo "Seed token (keep if you want to reseed later): $TOKEN"
else
  echo "Could not parse worker URL from deploy output; run scripts/seed-demo.sh <url> $TOKEN manually."
fi
