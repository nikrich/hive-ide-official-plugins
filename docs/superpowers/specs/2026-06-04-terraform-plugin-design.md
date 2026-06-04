# Terraform plugin — design

**Date:** 2026-06-04
**Status:** Approved

## Goal

Add a `terraform/` plugin to `hive-ide-official-plugins` giving Hive IDE
full Terraform/HCL language support: syntax highlighting plus LSP features
(diagnostics, completion, hover, go-to-definition, formatting) via
HashiCorp's `terraform-ls`.

It follows the existing `java/` plugin pattern (an LSP plugin that bundles
an external server through `setup.downloads`), adapted for the fact that
`terraform-ls` is a **native per-OS/arch binary** rather than a single
cross-platform JVM tarball.

## Server

- **terraform-ls 0.38.6** (latest stable as of 2026-06-04).
- Launched as `terraform-ls serve` (stdio transport).
- The `terraform` CLI is **not required** — terraform-ls parses HCL
  itself. Noted as optional in the README.

## Files

```
terraform/
  plugin.json
  grammar.json
  language-configuration.json
  launch.sh
  launch.cmd
  README.md
```

Plus an update to the top-level `README.md` plugin table.

### plugin.json

- `id`: `hive-ide-official-plugins/terraform`
- `name`: `Terraform`
- `version`: `0.1.0`
- `engines.hive`: `^0.1.0`
- `contributes.languages[0]`:
  - `id`: `terraform`
  - `extensions`: `[".tf", ".tfvars"]`
  - `aliases`: `["Terraform", "HCL"]`
  - `configuration`: `./language-configuration.json`
  - `grammar`: `./grammar.json`
- `contributes.languageServers[0]`:
  - `language`: `terraform`
  - `command`: `${pluginDir}/launch.sh`
  - `args`: `[]`
  - `transport`: `stdio`
  - `cwd`: `${pluginDir}`
- `setup.downloads`: five entries (see below).

### setup.downloads — platform handling

The IDE has **no platform-conditional download mechanism** (verified
against hive-ide source: `loader.ts` `parseSetupDownloads` accepts only
`url` / `extractTo` / `sha256` / `archive`; `setup.ts` loops over every
download unconditionally; the only `${pluginDir}` substitution is
launch-time, not applied to download URLs). Therefore all platform
binaries download on first enable and the **launcher** selects the
matching one at runtime via `uname`.

Each entry is a version-pinned zip (URLs are stable, so `sha256` is
included — an improvement over the Java plugin's unverified mirror):

| extractTo | artifact | sha256 |
|---|---|---|
| `./server/darwin_amd64` | `terraform-ls_0.38.6_darwin_amd64.zip` | `9c13350a6d99e48ab6ecaa0b8ad0fe52b7f5651a161091d2ee5d19fba3b25bf6` |
| `./server/darwin_arm64` | `terraform-ls_0.38.6_darwin_arm64.zip` | `ec1e20208ce7da55dc8798e280cc363535793e8827b6f97801184d7f21b2d08b` |
| `./server/linux_amd64` | `terraform-ls_0.38.6_linux_amd64.zip` | `79877f94a8eb175e6a58cf177839b0801acbfeccf968a2102e95d470fa3ad4a5` |
| `./server/linux_arm64` | `terraform-ls_0.38.6_linux_arm64.zip` | `a44b3df099f0ad8e88c96ea1110f965affee6e69b68ec44df25a593f5ee66cf3` |
| `./server/windows_amd64` | `terraform-ls_0.38.6_windows_amd64.zip` | `8dcc3a23a8166f5942575d64f6ff5467f6d501fa72bff89941b8cbaeb5ee3de2` |

URL base: `https://releases.hashicorp.com/terraform-ls/0.38.6/`
Each zip contains a single binary: `terraform-ls` (`terraform-ls.exe` on
Windows). `archive`: `"zip"`.

**Trade-off:** first enable downloads ~5×~20MB ≈ 100MB; four binaries sit
unused. This is the cost of staying within the documented
`setup.downloads` mechanism rather than fetching in the launcher (which
CONTRIBUTING §11 discourages for security). Trimming this would require a
`platform` filter in the IDE's download schema — out of scope for this
plugin.

### launch.sh (POSIX)

1. `HERE` = script dir.
2. Map `uname -s`: `Darwin`→`darwin`, `Linux`→`linux` (default `linux`).
3. Map `uname -m`: `x86_64`/`amd64`→`amd64`, `arm64`/`aarch64`→`arm64`.
4. `BIN="${HERE}/server/${OS}_${ARCH}/terraform-ls"`.
5. If `BIN` missing → friendly error to stderr naming the platform, exit 1.
6. `chmod +x "$BIN"` if not already executable (zip extraction may drop
   the bit).
7. `exec "$BIN" serve`.
8. `set -euo pipefail` at top.

### launch.cmd (Windows)

- `BIN=%HERE%\server\windows_amd64\terraform-ls.exe`.
- Error to stderr if missing.
- Run `"%BIN%" serve`.
- (Windows arm64 is downloaded for completeness only if added later; v1
  ships the amd64 launcher path, matching the single Windows download.)

### grammar.json (Monarch / HCL)

- `blockKeywords`: `resource`, `data`, `variable`, `output`, `module`,
  `provider`, `terraform`, `locals`, `moved`, `import`, `check`.
- `keywords`: `for`, `in`, `if`, `else`, `endfor`, `endif`.
- `literals`: `true`, `false`, `null`.
- Comments: `#` and `//` line, `/* */` block.
- Strings: double-quoted with `${ ... }` interpolation highlighted;
  heredocs `<<EOF` / `<<-EOF`.
- Numbers, brackets, operators, delimiters.

### language-configuration.json

- `comments`: `lineComment` `#`, `blockComment` `["/*", "*/"]`.
- `brackets`: `{}`, `[]`, `()`.
- `autoClosingPairs`: brackets, `"`, and `${`→`}`.
- `surroundingPairs`: brackets and `"`.

### README.md

Sections: title, requirements (none beyond the IDE; `terraform` CLI
optional), install (From GitHub, tag `terraform-vX.Y.Z`), first-enable
download note (~100MB, all platforms), features (LSP standard set),
troubleshooting, reporting bugs.

## Release

Tag `terraform-v0.1.0` triggers the existing
`.github/workflows/release.yml`, which tarballs the `terraform/` folder.

## Out of scope

- Platform-aware downloads (would require an IDE schema change).
- Windows arm64 launcher selection.
- `.tf.json` (that's JSON, handled by a JSON plugin).
- Bundling the `terraform` CLI.
