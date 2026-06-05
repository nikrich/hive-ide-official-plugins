#!/usr/bin/env bash
set -euo pipefail

GOPLS="$(command -v gopls || true)"
if [ -z "$GOPLS" ]; then
  CAND="${GOPATH:-$HOME/go}/bin/gopls"
  [ -x "$CAND" ] && GOPLS="$CAND"
fi

if [ -z "$GOPLS" ]; then
  if command -v go >/dev/null 2>&1; then
    echo "Hive IDE Go plugin: 'gopls' not found. Install it with: go install golang.org/x/tools/gopls@latest" >&2
  else
    echo "Hive IDE Go plugin: 'gopls' and the Go toolchain are not installed. Install Go from https://go.dev/dl/ then run: go install golang.org/x/tools/gopls@latest" >&2
  fi
  exit 1
fi

exec "$GOPLS" serve
