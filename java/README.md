# Java plugin for Hive IDE

Java language support via Eclipse JDT Language Server (jdtls).

## Requirements

- **JDK 21 or newer** on your PATH (or `JAVA_HOME` set). jdtls won't start
  on Java < 17.
- On macOS: `brew install openjdk@21` and follow the post-install steps
  to symlink it onto `/Library/Java/JavaVirtualMachines/`.
- On Windows: download Temurin 21 from adoptium.net and ensure `java`
  is on your PATH.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `java-vX.Y.Z` (use the latest java-prefixed tag).

On first enable, the IDE downloads ~80MB of jdtls into the plugin
folder. This takes a minute or two depending on bandwidth.

> **Note:** the jdtls download is **not sha256-verified** — the
> Eclipse mirror redirects, which makes a stable hash brittle. If you
> need bit-for-bit reproducibility, fork this plugin and pin the
> tarball to a hash-stable mirror, then add `sha256` to the manifest.

## Features

Powered by jdtls, you get the LSP standard set:

- Diagnostics (errors, warnings, info)
- Completion (members, imports, keywords, snippets)
- Hover (signatures, javadoc)
- Signature help
- Goto definition / type definition / implementation
- Find references
- Rename refactor
- Format document / range
- Code actions / quick fixes
- Document / workspace symbols

## Troubleshooting

- "jdtls won't start" → check `java -version` on your terminal. Must be 21+.
- "Setup download failed" → the eclipse mirror occasionally 404s.
  Retry by toggling the plugin off and back on.
- "First open is slow" → jdtls indexes your project. Give it 30–60s
  on a fresh open; subsequent opens reuse the cached index.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
