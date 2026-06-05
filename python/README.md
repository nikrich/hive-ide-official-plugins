# Python plugin for Hive IDE

Python language support via
[Pyright](https://github.com/microsoft/pyright) (Microsoft's static type
checker and language server).

## Requirements

- **Node.js 18+** on your PATH. Pyright is a Node program (like the Java
  plugin needs a JDK). Check with `node --version`.
- **A Python interpreter is optional but recommended.** Pyright bundles
  typeshed for the standard library, but resolves third-party imports from
  your active environment. It auto-detects `python` and virtualenvs; if
  third-party imports show as unresolved, make sure your project's
  interpreter / venv is discoverable.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `python-vX.Y.Z` (use the latest python-prefixed tag).

On first enable, the IDE downloads the Pyright server (~10MB, a single
cross-platform bundle). This is a one-time download.

## Features

Powered by Pyright, you get the LSP standard set:

- Diagnostics (type checking, undefined names, unused imports)
- Completion (members, imports, keywords)
- Hover (types and docstrings)
- Signature help
- Goto definition / declaration
- Find references
- Document / workspace symbols
- Call hierarchy
- Code actions

## Troubleshooting

- "Server won't start" → run `node --version`. If missing, install Node 18+.
  If Node is present, the setup download may have failed — toggle the
  plugin off and back on.
- "Third-party imports unresolved" → Pyright can't find your environment.
  Open the project at its root and ensure your venv / interpreter is in a
  standard location.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
