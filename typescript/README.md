# TypeScript / JavaScript plugin for Hive IDE

TypeScript and JavaScript language support via
[typescript-language-server](https://github.com/typescript-language-server/typescript-language-server),
which drives Microsoft's `tsserver` (bundled).

## Requirements

- **Node.js 20+** on your PATH. typescript-language-server is a Node
  program and its engine requires Node 20 or newer. Check with
  `node --version`.
- **A project is recommended.** Open your project at its root so `tsserver`
  can discover `tsconfig.json` / `jsconfig.json` and resolve modules.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `typescript-vX.Y.Z` (use the latest typescript-prefixed tag).

On first enable, the IDE downloads typescript-language-server and the
TypeScript package (two npm tarballs). This is a one-time download.

## Features

Powered by typescript-language-server + tsserver, you get the LSP standard
set:

- Diagnostics (type errors, undefined names)
- Completion (members, imports, keywords)
- Hover (types and JSDoc)
- Signature help
- Goto definition / type definition / implementation
- Find references
- Document / workspace symbols
- Rename
- Code actions (quick fixes, organize imports)

Languages: `typescript` (`.ts`), `typescriptreact` (`.tsx`),
`javascript` (`.js`, `.mjs`, `.cjs`), `javascriptreact` (`.jsx`).

## Troubleshooting

- "Server won't start" → run `node --version`. If missing or older than 20,
  install Node 20+. If Node is present, the setup download may have failed —
  toggle the plugin off and back on.
- "Imports unresolved / no project context" → open the project at its root
  so `tsserver` can find your `tsconfig.json` / `jsconfig.json`.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
