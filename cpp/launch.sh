#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) DIR="${HERE}/server/mac" ;;
  Linux)
    case "$(uname -m)" in
      x86_64|amd64) DIR="${HERE}/server/linux_amd64" ;;
      *) echo "Hive IDE C/C++ plugin: clangd has no Linux-$(uname -m) build upstream. Install clangd via your package manager and use it directly." >&2; exit 1 ;;
    esac ;;
  *) DIR="${HERE}/server/linux_amd64" ;;
esac

BIN="${DIR}/clangd_22.1.0/bin/clangd"
if [ ! -f "$BIN" ]; then
  echo "Hive IDE C/C++ plugin: clangd not found at ${BIN}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"
# Strip macOS quarantine so the unsigned binary starts without a prompt.
[ "$(uname -s)" = "Darwin" ] && xattr -dr com.apple.quarantine "$DIR" 2>/dev/null || true

exec "$BIN" --background-index
