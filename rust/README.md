# Rust plugin for Hive IDE

Rust language support via
[rust-analyzer](https://github.com/rust-lang/rust-analyzer), the official
Rust language server.

## Requirements

- **None to start.** The plugin downloads a prebuilt rust-analyzer binary
  for your platform on first enable.
- **A Rust toolchain is optional but recommended.** Install
  [rustup](https://rustup.rs/) so `cargo` and `rustc` are on your PATH.
  rust-analyzer answers basic requests without a toolchain, but full
  analysis (dependency resolution, `cargo check` diagnostics, proc-macro
  expansion) needs cargo and a `Cargo.toml`-rooted project.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `rust-vX.Y.Z` (use the latest rust-prefixed tag).

On first enable, the IDE downloads the rust-analyzer binary for your
platform (~20MB, a single gzipped binary on macOS/Linux). This is a
one-time download.

This plugin pins the rust-analyzer release tag **`2026-06-01`**.
rust-analyzer ships on a weekly cadence; the pinned tag is updated in new
plugin releases.

## Features

Powered by rust-analyzer, you get the LSP standard set:

- Diagnostics (`cargo check`, type errors, unused code)
- Completion (members, paths, keywords, snippets)
- Hover (types, docs)
- Signature help
- Goto definition / declaration / implementation
- Find references
- Document / workspace symbols
- Inlay hints (types, parameter names)
- Code actions and refactors

## Troubleshooting

- "Server won't start" → the setup download may have failed; toggle the
  plugin off and back on to re-download.
- "No diagnostics / unresolved imports" → rust-analyzer needs a Cargo
  project. Open the folder containing `Cargo.toml` and ensure `cargo` is on
  your PATH (`cargo --version`). Install via [rustup](https://rustup.rs/).
- **Windows on ARM / Linux on a different arch** → only the platforms listed
  in `plugin.json` are bundled. Install rust-analyzer via rustup
  (`rustup component add rust-analyzer`) if your platform is unsupported.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
