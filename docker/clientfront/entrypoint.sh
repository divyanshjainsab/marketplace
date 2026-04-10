#!/bin/sh
set -e

CHECKSUM_FILE="node_modules/.deps-checksum"
CURRENT_CHECKSUM="$(sha256sum package.json 2>/dev/null | awk '{print $1}')"
STORED_CHECKSUM="$(cat "$CHECKSUM_FILE" 2>/dev/null || true)"

if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ] || [ "$CURRENT_CHECKSUM" != "$STORED_CHECKSUM" ]; then
  npm install
  if [ -n "$CURRENT_CHECKSUM" ]; then
    echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
  fi
fi

exec "$@"
