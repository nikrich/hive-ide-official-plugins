# Terraform plugin for Hive IDE

Terraform / HCL language support via
[terraform-ls](https://github.com/hashicorp/terraform-ls) (HashiCorp's
official language server).

## Requirements

None beyond Hive IDE itself. The language server is bundled and downloaded
on first enable. The `terraform` CLI is **optional** — terraform-ls parses
HCL on its own; install Terraform only if you want the server to resolve
provider schemas from your initialized working directory.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `terraform-vX.Y.Z` (use the latest terraform-prefixed tag).

On first enable, the IDE downloads terraform-ls binaries for **all
supported platforms** (~100MB total; only the one matching your OS/arch is
used). This is a one-time download. It happens because the plugin runtime
has no per-platform download selection — see the plugin's design notes.

## Features

Powered by terraform-ls, you get the LSP standard set:

- Diagnostics (HCL syntax + validation)
- Completion (blocks, attributes, providers, module inputs)
- Hover (attribute and block documentation)
- Goto definition (modules, variables, locals)
- Document formatting (`terraform fmt` semantics)
- Document symbols
- Code actions

## Supported platforms

macOS (Intel + Apple Silicon), Linux (amd64 + arm64), Windows (amd64).

## Troubleshooting

- "Server won't start" → the setup download may have failed. Toggle the
  plugin off and back on to re-run setup.
- "No terraform-ls binary for <platform>" → your OS/arch isn't among the
  bundled binaries (e.g. Windows arm64). File an issue to request it.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
