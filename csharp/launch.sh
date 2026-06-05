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
BIN="${DIR}/OmniSharp"
if [ ! -f "$BIN" ]; then
  echo "Hive IDE C# plugin: OmniSharp binary for ${OS}_${ARCH} not found in ${DIR}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"
[ "$(uname -s)" = "Darwin" ] && xattr -dr com.apple.quarantine "$DIR" 2>/dev/null || true

if ! command -v dotnet >/dev/null 2>&1; then
  echo "Hive IDE C# plugin: '.NET runtime' not found. OmniSharp needs the .NET 6+ runtime — install it from https://dotnet.microsoft.com/download and ensure 'dotnet' is on PATH." >&2
  exit 1
fi

exec "$BIN" -lsp -s "${PWD}"
