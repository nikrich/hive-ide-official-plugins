# Go plugin for Hive IDE

Go language support via [gopls](https://pkg.go.dev/golang.org/x/tools/gopls)
(the official Go language server, maintained by the Go team).

## Requirements

gopls is **not bundled** — there are no prebuilt gopls binaries upstream, so
this plugin runs the `gopls` already installed on your machine. You need two
things on your PATH:

1. **The Go toolchain.** Install from <https://go.dev/dl/>. Check with
   `go version`.
2. **gopls.** Once Go is installed, run:

   ```sh
   go install golang.org/x/tools/gopls@latest
   ```

   This builds `gopls` into `$GOPATH/bin` (default `~/go/bin`).

### PATH gotcha — `~/go/bin`

`go install` drops `gopls` in `~/go/bin` (or `$GOPATH/bin`), which is **not on
your PATH by default**. If `gopls` isn't found, either:

- add it to your shell PATH, e.g. `export PATH="$PATH:$(go env GOPATH)/bin"`
  in your `~/.zshrc` / `~/.bashrc`, or
- rely on this plugin's launcher, which also probes
  `${GOPATH:-$HOME/go}/bin/gopls` automatically.

On Windows the launcher additionally probes `%USERPROFILE%\go\bin\gopls.exe`.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `go-vX.Y.Z` (use the latest go-prefixed tag).

There is no first-enable download — the plugin uses your locally installed
gopls.

## Features

Powered by gopls, you get the LSP standard set:

- Diagnostics (type errors, unused variables, vet checks)
- Completion (members, packages, keywords)
- Hover (types and documentation)
- Signature help
- Goto definition / type definition / implementation
- Find references
- Document / workspace symbols
- Rename and code actions (organize imports, quick fixes)
- Inlay hints

Open your module at its root (the directory containing `go.mod`) so gopls can
resolve the build and dependencies.

## Troubleshooting

- "Server won't start: gopls not found" → run `go install
  golang.org/x/tools/gopls@latest`, then make sure `~/go/bin` (or
  `$GOPATH/bin`) is on your PATH (see the PATH gotcha above).
- "go: command not found" → install the Go toolchain from
  <https://go.dev/dl/>.
- "No completions / unresolved imports" → open the project at its module root
  (where `go.mod` lives) and let gopls finish loading the build.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
