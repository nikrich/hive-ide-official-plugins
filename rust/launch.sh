#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)      OS="linux" ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             ARCH="amd64" ;;
esac

DIR="${HERE}/server/${OS}_${ARCH}"
BIN="${DIR}/rust-analyzer"

# Unix assets ship as a single gzipped binary; decompress on first run.
if [ ! -f "$BIN" ]; then
  GZ="$(ls "${DIR}/"*.gz 2>/dev/null | head -1 || true)"
  if [ -n "$GZ" ]; then
    gunzip -c "$GZ" > "$BIN"
    chmod +x "$BIN"
  fi
fi

if [ ! -f "$BIN" ]; then
  echo "Hive IDE Rust plugin: rust-analyzer binary for ${OS}_${ARCH} not found in ${DIR}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"

exec "$BIN"
