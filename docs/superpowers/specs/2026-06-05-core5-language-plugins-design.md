# Core 5 language plugins — design

**Date:** 2026-06-05
**Status:** Approved

## Goal

Add five language plugins to `hive-ide-official-plugins`, each following the
proven `java/`/`terraform/`/`python/` pattern (manifest + Monarch grammar +
language-configuration + cross-platform launchers + README; server fetched
via `setup.downloads`; verified with a real LSP `initialize` smoke test):

1. **typescript** — TypeScript + JavaScript via typescript-language-server
2. **rust** — via rust-analyzer
3. **cpp** — C and C++ via clangd
4. **csharp** — via OmniSharp-roslyn
5. **go** — via gopls

They are independent; each ships, versions, and releases on its own
(`<lang>-v0.1.0` tag). All server facts below were verified against live
upstream sources on 2026-06-05.

## Shared template (identical to the python/ plugin)

Each plugin folder contains: `plugin.json`, `grammar.json`,
`language-configuration.json`, `launch.sh` (POSIX, committed `100755`),
`launch.cmd` (Windows), `README.md`. Plus a row in the top-level
`README.md` table. `engines.hive` is `^0.1.0`; version `0.1.0`. Manifests
use `${pluginDir}/launch.sh` as the `command`, `stdio` transport. Launchers
use `set -euo pipefail`, emit friendly stderr errors, and never fetch from
the network (CONTRIBUTING §11) — first-run work is local filesystem only.

**Checksums:** rust-analyzer, clangd, and OmniSharp publish no upstream
checksums; their `sha256` values are **computed at build time** from the
downloaded artifact and pinned in the manifest. npm tarballs (typescript)
are immutable, so their sha256 is also computed-and-pinned. Go has no
download.

**Server binaries are never committed** (CONTRIBUTING §10) — they download
on first enable. The smoke test downloads into the plugin folder, verifies,
then deletes before commit.

---

## 1. typescript plugin

- **Server:** typescript-language-server **5.3.0** + typescript **6.0.3**
  (provides `tsserver`). Both npm tarballs.
- **Runtime:** Node.js 18+ on PATH (server engine requires >=20; README says
  Node 20+).
- **Languages:** ids/extensions —
  `typescript` (`.ts`), `typescriptreact` (`.tsx`),
  `javascript` (`.js`, `.mjs`, `.cjs`), `javascriptreact` (`.jsx`).
  One grammar may be shared (register the TS grammar for all; JSX nuance is
  out of scope for v1 highlighting).
- **Downloads (two entries, both `archive: tar.gz`):**
  - `https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-5.3.0.tgz` → `./server/tls`
  - `https://registry.npmjs.org/typescript/-/typescript-6.0.3.tgz` → `./server/ts`
  - sha256 of each computed at build time.
- **Extraction layout:** each tarball extracts to a `package/` subdir, so:
  - server entry: `./server/tls/package/lib/cli.mjs`
  - typescript pkg: `./server/ts/package/` (contains `package.json` name
    `typescript`, `lib/tsserver.js`).
- **tsserver wiring (the wrinkle):** the server calls
  `require.resolve('typescript')` from `cli.mjs`. It must find a directory
  literally named `typescript`. The launcher creates a one-time symlink
  `./server/ts/typescript -> package` (idempotent), then runs node with
  `NODE_PATH=${HERE}/server/ts` so resolution finds
  `./server/ts/typescript/lib/typescript.js` → `tsserver.js`.
- **launch.sh logic:** locate `node` (error if missing); ensure symlink
  `server/ts/typescript` exists (`ln -sfn package server/ts/typescript`);
  ensure `server/tls/package/lib/cli.mjs` exists (else download-failed
  error); `exec env NODE_PATH="${HERE}/server/ts" "$NODE_BIN" "${HERE}/server/tls/package/lib/cli.mjs" --stdio`.
- **launch.cmd:** `where node`; create a `server\ts\typescript` directory
  junction to `package` via `mklink /J` (idempotent: skip if exists); run
  `node` with `NODE_PATH` set to `%HERE%\server\ts`.
- **Smoke test:** download both tarballs, extract, create symlink, launch
  via `launch.sh`, confirm `initialize` answers with capabilities.

## 2. rust plugin

- **Server:** rust-analyzer release tag **`2026-06-01`**.
- **Runtime:** none to start; a Rust toolchain (cargo/rustc) on PATH is
  recommended for full analysis (README note).
- **Language:** id `rust`, extension `.rs`.
- **Downloads (per-platform; the unix assets are single gzipped binaries,
  NOT tar.gz):**
  | extractTo | asset | archive |
  |---|---|---|
  | `./server/darwin_arm64` | `rust-analyzer-aarch64-apple-darwin.gz` | `none` |
  | `./server/darwin_amd64` | `rust-analyzer-x86_64-apple-darwin.gz` | `none` |
  | `./server/linux_amd64` | `rust-analyzer-x86_64-unknown-linux-gnu.gz` | `none` |
  | `./server/linux_arm64` | `rust-analyzer-aarch64-unknown-linux-gnu.gz` | `none` |
  | `./server/windows_amd64` | `rust-analyzer-x86_64-pc-windows-msvc.zip` | `zip` |
  - URL base: `https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/`
  - `archive: none` lands the file at `extractTo/<basename>` (e.g.
    `./server/darwin_arm64/rust-analyzer-aarch64-apple-darwin.gz`).
  - sha256 of each computed at build time.
- **launch.sh logic (the wrinkle):** map `uname` → `${OS}_${ARCH}`; let
  `DIR=${HERE}/server/${OS}_${ARCH}`. If `${DIR}/rust-analyzer` does not
  exist but a `*.gz` does, `gunzip -c "$GZ" > "$DIR/rust-analyzer"` then
  `chmod +x`. Error if neither present. `exec "$DIR/rust-analyzer"` (stdio,
  no args). Windows: zip extracts `rust-analyzer.exe`; launch.cmd runs it
  directly.
- **Smoke test:** download host `.gz`, gunzip, launch via `launch.sh`,
  confirm `initialize`.

## 3. cpp plugin

- **Server:** clangd **22.1.0** (clangd/clangd standalone release).
- **Runtime:** none. `compile_commands.json` recommended for full features
  (README note).
- **Languages:** two ids — `c` (`.c`, `.h`) and `cpp` (`.cpp`, `.cc`,
  `.cxx`, `.c++`, `.hpp`, `.hh`, `.hxx`, `.h++`). One clangd server entry
  registered for both ids.
- **Downloads (per-platform `.zip`; only THREE platforms exist):**
  | extractTo | asset | covers |
  |---|---|---|
  | `./server/mac` | `clangd-mac-22.1.0.zip` | darwin arm64 + amd64 (universal binary) |
  | `./server/linux_amd64` | `clangd-linux-22.1.0.zip` | linux x64 |
  | `./server/windows_amd64` | `clangd-windows-22.1.0.zip` | windows x64 |
  - URL base: `https://github.com/clangd/clangd/releases/download/22.1.0/`
  - **No linux_arm64 build exists** — launcher errors on that platform.
  - Binary inside each zip: `clangd_22.1.0/bin/clangd` (`.exe` on Windows).
    The sibling `clangd_22.1.0/lib/clang/...` headers must remain in place
    (full extraction; launcher references the versioned subdir).
  - sha256 of each computed at build time.
- **launch.sh logic:** if `uname -s` is Darwin → `DIR=server/mac`; Linux
  x86_64 → `server/linux_amd64`; Linux aarch64 → error "clangd has no
  Linux-arm64 build". `BIN=${DIR}/clangd_22.1.0/bin/clangd`. `chmod +x` if
  needed; on macOS `xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true`.
  `exec "$BIN" --background-index`. Windows launch.cmd:
  `server\windows_amd64\clangd_22.1.0\bin\clangd.exe --background-index`.
- **Smoke test:** download host zip, extract, launch via `launch.sh`,
  confirm `initialize`.

## 4. csharp plugin

- **Server:** OmniSharp-roslyn **v1.39.15** (net6 builds).
- **Runtime:** **.NET 6+ runtime on PATH** (`dotnet`). The net6 builds are
  framework-dependent (not self-contained). README states this.
- **Language:** id `csharp`, extensions `.cs`, `.csx`.
- **Downloads (per-platform `.zip`, all 5 platforms; ~46–50MB each):**
  | extractTo | asset |
  |---|---|
  | `./server/darwin_arm64` | `omnisharp-osx-arm64-net6.0.zip` |
  | `./server/darwin_amd64` | `omnisharp-osx-x64-net6.0.zip` |
  | `./server/linux_amd64` | `omnisharp-linux-x64-net6.0.zip` |
  | `./server/linux_arm64` | `omnisharp-linux-arm64-net6.0.zip` |
  | `./server/windows_amd64` | `omnisharp-win-x64-net6.0.zip` |
  - URL base: `https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/`
  - Executable at archive root: `OmniSharp` (`OmniSharp.exe` on Windows).
  - sha256 of each computed at build time.
- **launch.sh logic:** map `uname` → `${OS}_${ARCH}`;
  `BIN=${HERE}/server/${OS}_${ARCH}/OmniSharp`. Error if missing (download
  failed). `chmod +x`; macOS `xattr -d com.apple.quarantine` (recursively on
  the server dir, best-effort). Check `command -v dotnet` — error with
  install link if absent. `exec "$BIN" -lsp -s "${PWD}"`. Windows analog.
- **Smoke test:** requires `dotnet` on the build host. Download host zip,
  extract, launch via `launch.sh`, confirm `initialize`. If `dotnet` is
  absent on the build machine, the smoke test cannot run — the builder must
  report this clearly rather than mark verified.

## 5. go plugin

- **Server:** gopls **v0.22.0** — **no prebuilt binaries exist**; not
  bundled. Requires the user to have installed it
  (`go install golang.org/x/tools/gopls@latest`).
- **Runtime:** Go toolchain + gopls on PATH.
- **Language:** id `go`, extension `.go`.
- **Downloads:** none (`setup` omitted entirely).
- **launch.sh logic:** `GOPLS=$(command -v gopls || true)`; if empty, also
  probe `${GOPATH:-$HOME/go}/bin/gopls`. If still missing: if `go` is on
  PATH → error "run: go install golang.org/x/tools/gopls@latest"; else →
  error "install Go from https://go.dev/dl/ then go install …". `exec
  "$GOPLS" serve`. `cwd` should be the workspace root (omit `cwd` in the
  manifest so the IDE default applies, OR set the manifest `cwd` to the
  workspace — the IDE substitutes workspace root by default; do NOT pin
  `${pluginDir}`). Windows launch.cmd: `where gopls`, else probe
  `%USERPROFILE%\go\bin\gopls.exe`, run `gopls serve`.
- **Smoke test:** if `gopls` is on the build host, launch via `launch.sh`
  and confirm `initialize`. If not installed, the builder runs
  `go install golang.org/x/tools/gopls@latest` first (build-host setup only,
  not in the launcher) to enable the smoke test, then verifies.

---

## Grammars (Monarch) — per language

Standard keyword/literal/comment/string/number tokenizers, mirroring the
quality of the existing python grammar. Key points:

- **typescript:** JS/TS keywords (`const`, `let`, `function`, `class`,
  `interface`, `type`, `enum`, `import`, `export`, `async`, `await`,
  `return`, `if`, `for`, `=>`, etc.), template literals with `${}`
  interpolation, `//` and `/* */` comments, regex-lite, decorators `@`.
- **rust:** keywords (`fn`, `let`, `mut`, `struct`, `enum`, `impl`, `trait`,
  `match`, `pub`, `use`, `mod`, `unsafe`, `async`, `await`, lifetimes
  `'a`), attributes `#[...]`, `//`/`/* */`, raw/byte strings, macros `name!`.
- **cpp:** C/C++ keywords + preprocessor `#include`/`#define`, `//`/`/* */`,
  char/string literals, numbers, `::`.
- **csharp:** keywords (`class`, `public`, `void`, `var`, `using`,
  `namespace`, `async`, `await`, `string`, etc.), `//`/`/* */`, `$"..."`
  interpolation, verbatim `@"..."`, attributes `[...]`.
- **go:** keywords (`func`, `package`, `import`, `var`, `const`, `type`,
  `struct`, `interface`, `map`, `chan`, `go`, `defer`, `range`, etc.),
  `//`/`/* */`, raw strings with backticks, runes.

## Parallel build-out

The five plugins are independent and build concurrently. Each build stream
(one agent, isolated git worktree + branch `feat/<lang>-plugin`):
1. Scaffold the six files from the template with this plugin's parameters.
2. Validate JSON + launcher syntax.
3. Download this plugin's server artifact(s), compute `sha256`, pin into
   the manifest. (Go: skip.)
4. Run the real LSP `initialize` smoke test on the build host's platform.
5. Delete the downloaded server bundle (never commit binaries).
6. Commit, push branch, open PR.

The controller then collects the five PRs. Releases (`<lang>-v0.1.0` tags)
are cut after merge, one per plugin, reusing the existing release workflow.

## Out of scope

- Bundling Node, .NET, or the Go toolchain.
- linux_arm64 for clangd (no upstream build).
- JSX/TSX semantic grammar nuance; f-string-style deep interpolation beyond
  basic `${}`.
- Debugging (DAP), notebooks.
- Platform-conditional downloads (an IDE-side enhancement, tracked
  separately).
