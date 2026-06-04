#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Map host OS to the terraform-ls release naming.
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)      OS="linux" ;;
esac

# Map host arch to the terraform-ls release naming.
case "$(uname -m)" in
  x86_64|amd64)   ARCH="amd64" ;;
  arm64|aarch64)  ARCH="arm64" ;;
  *)              ARCH="amd64" ;;
esac

BIN="${HERE}/server/${OS}_${ARCH}/terraform-ls"

if [ ! -f "$BIN" ]; then
  echo "Hive IDE Terraform plugin: no terraform-ls binary for ${OS}_${ARCH} at ${BIN}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

# Zip extraction can drop the executable bit; restore it.
[ -x "$BIN" ] || chmod +x "$BIN"

exec "$BIN" serve
