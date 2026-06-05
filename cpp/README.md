# C / C++ plugin for Hive IDE

C and C++ language support via
[clangd](https://clangd.llvm.org/) (the LLVM language server).

## Requirements

- **None.** clangd is a self-contained native binary — there is no runtime
  dependency (no Node, no JDK, no toolchain needed to start the server).
- **`compile_commands.json` is recommended** for full features. Without it,
  clangd uses heuristics and may not resolve all includes or flags. Generate
  one with CMake (`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`) or
  [Bear](https://github.com/rizsotto/Bear) (`bear -- make`) and place it at
  your project root (or a `build/` dir).

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `cpp-vX.Y.Z` (use the latest cpp-prefixed tag).

On first enable, the IDE downloads the clangd server for your platform (a
one-time download). Builds are provided for **macOS** (universal — Apple
Silicon and Intel), **Linux x64**, and **Windows x64**.

> **Note:** there is no upstream clangd build for **Linux arm64**. On that
> platform, install clangd via your package manager and use it directly.

## Features

Powered by clangd, you get the LSP standard set:

- Diagnostics (clang warnings/errors, clang-tidy)
- Completion (members, functions, includes)
- Hover (types, signatures, documentation)
- Signature help
- Goto definition / declaration
- Find references
- Document / workspace symbols
- Code actions (fix-its, includes)
- Rename

## Troubleshooting

- "Server won't start" → the setup download may have failed; toggle the
  plugin off and back on to re-download. On Linux arm64, clangd has no
  upstream build — install it via your package manager.
- "Includes / symbols unresolved" → add a `compile_commands.json` at your
  project root so clangd knows your compile flags and include paths.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
