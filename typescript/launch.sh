#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "Hive IDE TypeScript plugin: no 'node' binary found. typescript-language-server runs on Node.js — install Node 20+ and ensure 'node' is on PATH." >&2
  exit 1
fi

CLI="${HERE}/server/tls/package/lib/cli.mjs"
if [ ! -f "$CLI" ]; then
  echo "Hive IDE TypeScript plugin: server not found at ${CLI}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

# tsserver wiring: the server resolves require('typescript') from a dir
# literally named 'typescript'. Point a symlink at the extracted package.
if [ ! -e "${HERE}/server/ts/typescript" ]; then
  ln -sfn package "${HERE}/server/ts/typescript"
fi

exec env NODE_PATH="${HERE}/server/ts" "$NODE_BIN" "$CLI" --stdio
