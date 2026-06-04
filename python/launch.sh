#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Locate node.
NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "Hive IDE Python plugin: no 'node' binary found. Pyright runs on Node.js — install Node 18+ and ensure 'node' is on PATH." >&2
  exit 1
fi

SERVER="${HERE}/server/package/langserver.index.js"
if [ ! -f "$SERVER" ]; then
  echo "Hive IDE Python plugin: Pyright server not found at ${SERVER}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

exec "$NODE_BIN" "$SERVER" --stdio
