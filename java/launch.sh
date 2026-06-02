#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
JDTLS_DIR="${HERE}/jdtls"

# Pick the platform launcher jar
LAUNCHER=$(ls "${JDTLS_DIR}/plugins/org.eclipse.equinox.launcher_"*.jar | head -1)

# Pick the platform config dir
case "$(uname -s)" in
  Darwin) CONFIG="${JDTLS_DIR}/config_mac" ;;
  Linux)  CONFIG="${JDTLS_DIR}/config_linux" ;;
  *)      CONFIG="${JDTLS_DIR}/config_linux" ;;
esac

# Data dir — one per user; jdtls re-uses it across sessions.
DATA_DIR="${HOME}/.hive-ide/jdtls-data"
mkdir -p "$DATA_DIR"

# Locate java
JAVA_BIN="${JAVA_HOME:+$JAVA_HOME/bin/java}"
if [ -z "$JAVA_BIN" ] || [ ! -x "$JAVA_BIN" ]; then
  JAVA_BIN="$(command -v java || true)"
fi
if [ -z "$JAVA_BIN" ]; then
  echo "Hive IDE Java plugin: no 'java' binary found. Install JDK 21+ and ensure 'java' is on PATH or JAVA_HOME is set." >&2
  exit 1
fi

exec "$JAVA_BIN" \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dlog.level=ALL \
  -Xmx1G \
  --add-modules=ALL-SYSTEM \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  -jar "$LAUNCHER" \
  -configuration "$CONFIG" \
  -data "$DATA_DIR"
