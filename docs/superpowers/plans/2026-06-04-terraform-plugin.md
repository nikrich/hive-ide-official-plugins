# Terraform Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `terraform/` plugin to hive-ide-official-plugins giving Hive IDE Terraform/HCL syntax highlighting plus full LSP features via HashiCorp's terraform-ls.

**Architecture:** A folder-only plugin (no compiled code) following the existing `java/` pattern: a `plugin.json` manifest registers the `terraform` language + a stdio language server, `setup.downloads` fetches five per-OS/arch `terraform-ls` binaries on first enable, and cross-platform launchers select the binary matching the host via `uname`.

**Tech Stack:** JSON manifest (hive plugin schema), Monarch grammar, Monaco LanguageConfiguration, POSIX `bash` + Windows `cmd` launchers, terraform-ls 0.38.6.

---

## File Structure

```
terraform/
  plugin.json                  # manifest: language + LSP + 5 platform downloads
  grammar.json                 # HCL Monarch tokenizer
  language-configuration.json  # comments, brackets, auto-close
  launch.sh                    # POSIX: uname -> server/<os>_<arch>/terraform-ls serve
  launch.cmd                   # Windows: server\windows_amd64\terraform-ls.exe serve
  README.md                    # install, features, troubleshooting
```
Plus one edit to the top-level `README.md` (plugin table row).

Reference files (read, don't modify): `java/plugin.json`, `java/launch.sh`, `java/launch.cmd`, `java/grammar.json`, `java/language-configuration.json`, `CONTRIBUTING.md`.

Verification base values (terraform-ls 0.38.6):
- URL base: `https://releases.hashicorp.com/terraform-ls/0.38.6/`
- darwin_amd64 sha256: `9c13350a6d99e48ab6ecaa0b8ad0fe52b7f5651a161091d2ee5d19fba3b25bf6`
- darwin_arm64 sha256: `ec1e20208ce7da55dc8798e280cc363535793e8827b6f97801184d7f21b2d08b`
- linux_amd64 sha256: `79877f94a8eb175e6a58cf177839b0801acbfeccf968a2102e95d470fa3ad4a5`
- linux_arm64 sha256: `a44b3df099f0ad8e88c96ea1110f965affee6e69b68ec44df25a593f5ee66cf3`
- windows_amd64 sha256: `8dcc3a23a8166f5942575d64f6ff5467f6d501fa72bff89941b8cbaeb5ee3de2`

---

## Task 1: Language configuration

**Files:**
- Create: `terraform/language-configuration.json`

- [ ] **Step 1: Write the file**

```json
{
  "comments": {
    "lineComment": "#",
    "blockComment": ["/*", "*/"]
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"", "notIn": ["string"] },
    { "open": "${", "close": "}" }
  ],
  "surroundingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"" }
  ]
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool terraform/language-configuration.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add terraform/language-configuration.json
git commit -m "feat(terraform): language configuration"
```

---

## Task 2: HCL grammar

**Files:**
- Create: `terraform/grammar.json`

- [ ] **Step 1: Write the file**

```json
{
  "defaultToken": "",
  "tokenPostfix": ".tf",
  "blockKeywords": [
    "resource", "data", "variable", "output", "module", "provider",
    "terraform", "locals", "moved", "import", "check", "removed"
  ],
  "keywords": [
    "for", "in", "if", "else", "endfor", "endif"
  ],
  "literals": ["true", "false", "null"],
  "symbols": "[=><!~?:&|+\\-*/^%]+",
  "operators": [
    "=", ">", "<", "!", "~", "?", ":", "==", "<=", ">=", "!=",
    "&&", "||", "+", "-", "*", "/", "%", "=>"
  ],
  "escapes": "\\\\(?:[nrt\\\\\"]|u[0-9A-Fa-f]{4})",
  "tokenizer": {
    "root": [
      ["[a-zA-Z_]\\w*(?=\\s*=[^=])", "variable"],
      ["[a-zA-Z_]\\w*", {
        "cases": {
          "@blockKeywords": "keyword",
          "@keywords": "keyword",
          "@literals": "keyword.literal",
          "@default": "identifier"
        }
      }],
      { "include": "@whitespace" },
      ["[{}()\\[\\]]", "@brackets"],
      ["@symbols", {
        "cases": {
          "@operators": "operator",
          "@default": ""
        }
      }],
      ["\\d+\\.\\d+([eE][\\-+]?\\d+)?", "number.float"],
      ["\\d+", "number"],
      ["[;,.]", "delimiter"],
      ["<<[-]?(\\w+)", { "token": "string.heredoc.delimiter", "next": "@heredoc.$1" }],
      ["\"", { "token": "string.quote", "bracket": "@open", "next": "@string" }]
    ],
    "whitespace": [
      ["[ \\t\\r\\n]+", "white"],
      ["#.*$", "comment"],
      ["//.*$", "comment"],
      ["/\\*", "comment", "@comment"]
    ],
    "comment": [
      ["[^/*]+", "comment"],
      ["\\*/", "comment", "@pop"],
      ["[/*]", "comment"]
    ],
    "string": [
      ["\\$\\{", { "token": "delimiter.interpolation", "next": "@interp" }],
      ["[^\\\\\"$]+", "string"],
      ["@escapes", "string.escape"],
      ["\\\\.", "string.escape.invalid"],
      ["\\$(?!\\{)", "string"],
      ["\"", { "token": "string.quote", "bracket": "@close", "next": "@pop" }]
    ],
    "interp": [
      ["\\}", { "token": "delimiter.interpolation", "next": "@pop" }],
      ["[a-zA-Z_]\\w*", "identifier"],
      ["@symbols", "operator"],
      ["[.,()\\[\\]]", "delimiter"],
      ["\\d+", "number"]
    ],
    "heredoc": [
      ["^\\s*([A-Za-z_]\\w*)\\s*$", {
        "cases": {
          "$1==$S2": { "token": "string.heredoc.delimiter", "next": "@pop" },
          "@default": "string.heredoc"
        }
      }],
      [".*$", "string.heredoc"]
    ]
  }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool terraform/grammar.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add terraform/grammar.json
git commit -m "feat(terraform): HCL Monarch grammar"
```

---

## Task 3: plugin.json manifest

**Files:**
- Create: `terraform/plugin.json`

- [ ] **Step 1: Write the file**

```json
{
  "id": "hive-ide-official-plugins/terraform",
  "name": "Terraform",
  "version": "0.1.0",
  "description": "Terraform/HCL language support via terraform-ls (HashiCorp). Bundles the language server; no extra runtime required.",
  "publisher": "hive-ide-official-plugins",
  "engines": {
    "hive": "^0.1.0"
  },
  "contributes": {
    "languages": [
      {
        "id": "terraform",
        "extensions": [
          ".tf",
          ".tfvars"
        ],
        "aliases": [
          "Terraform",
          "HCL"
        ],
        "configuration": "./language-configuration.json",
        "grammar": "./grammar.json"
      }
    ],
    "languageServers": [
      {
        "language": "terraform",
        "command": "${pluginDir}/launch.sh",
        "args": [],
        "transport": "stdio",
        "cwd": "${pluginDir}"
      }
    ]
  },
  "setup": {
    "downloads": [
      {
        "url": "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_darwin_amd64.zip",
        "extractTo": "./server/darwin_amd64",
        "sha256": "9c13350a6d99e48ab6ecaa0b8ad0fe52b7f5651a161091d2ee5d19fba3b25bf6",
        "archive": "zip"
      },
      {
        "url": "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_darwin_arm64.zip",
        "extractTo": "./server/darwin_arm64",
        "sha256": "ec1e20208ce7da55dc8798e280cc363535793e8827b6f97801184d7f21b2d08b",
        "archive": "zip"
      },
      {
        "url": "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_linux_amd64.zip",
        "extractTo": "./server/linux_amd64",
        "sha256": "79877f94a8eb175e6a58cf177839b0801acbfeccf968a2102e95d470fa3ad4a5",
        "archive": "zip"
      },
      {
        "url": "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_linux_arm64.zip",
        "extractTo": "./server/linux_arm64",
        "sha256": "a44b3df099f0ad8e88c96ea1110f965affee6e69b68ec44df25a593f5ee66cf3",
        "archive": "zip"
      },
      {
        "url": "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_windows_amd64.zip",
        "extractTo": "./server/windows_amd64",
        "sha256": "8dcc3a23a8166f5942575d64f6ff5467f6d501fa72bff89941b8cbaeb5ee3de2",
        "archive": "zip"
      }
    ]
  }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool terraform/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify schema-critical fields with a check script**

Run:
```bash
python3 - <<'PY'
import json
m = json.load(open("terraform/plugin.json"))
assert m["id"] == "hive-ide-official-plugins/terraform"
lang = m["contributes"]["languages"][0]
assert lang["id"] == "terraform"
assert lang["extensions"] == [".tf", ".tfvars"]
srv = m["contributes"]["languageServers"][0]
assert srv["language"] == "terraform"
assert srv["transport"] == "stdio"
assert "${pluginDir}/launch.sh" == srv["command"]
dls = m["setup"]["downloads"]
assert len(dls) == 5, len(dls)
for d in dls:
    assert d["url"].startswith("https://"), d["url"]
    assert d["archive"] == "zip"
    assert len(d["sha256"]) == 64
    assert d["extractTo"].startswith("./server/")
print("OK")
PY
```
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add terraform/plugin.json
git commit -m "feat(terraform): plugin manifest with terraform-ls 0.38.6 downloads"
```

---

## Task 4: POSIX launcher

**Files:**
- Create: `terraform/launch.sh`

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Map host OS to the terraform-ls release naming.
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)      OS="linux" ;;
esac

# Map host arch to the terraform-ls release naming.
case "$(uname -m)" in
  x86_64|amd64)   ARCH="amd64" ;;
  arm64|aarch64)  ARCH="arm64" ;;
  *)              ARCH="amd64" ;;
esac

BIN="${HERE}/server/${OS}_${ARCH}/terraform-ls"

if [ ! -f "$BIN" ]; then
  echo "Hive IDE Terraform plugin: no terraform-ls binary for ${OS}_${ARCH} at ${BIN}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

# Zip extraction can drop the executable bit; restore it.
[ -x "$BIN" ] || chmod +x "$BIN"

exec "$BIN" serve
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x terraform/launch.sh && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify bash syntax**

Run: `bash -n terraform/launch.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Verify platform-selection logic resolves a path (binary not yet present)**

Run:
```bash
cd terraform && bash -c '
  case "$(uname -s)" in Darwin) OS=darwin;; Linux) OS=linux;; *) OS=linux;; esac
  case "$(uname -m)" in x86_64|amd64) ARCH=amd64;; arm64|aarch64) ARCH=arm64;; *) ARCH=amd64;; esac
  echo "resolved: server/${OS}_${ARCH}/terraform-ls"
'; cd ..
```
Expected: a line like `resolved: server/darwin_arm64/terraform-ls` matching this host.

- [ ] **Step 5: Commit**

```bash
git add terraform/launch.sh
git commit -m "feat(terraform): POSIX launcher with platform selection"
```

---

## Task 5: Windows launcher

**Files:**
- Create: `terraform/launch.cmd`

- [ ] **Step 1: Write the file**

```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\terraform-ls.exe"

if not exist "%BIN%" (
  echo Hive IDE Terraform plugin: terraform-ls.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%BIN%" serve
```

- [ ] **Step 2: Verify it is non-empty and references the windows binary**

Run: `grep -q 'windows_amd64\\\\terraform-ls.exe' terraform/launch.cmd && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add terraform/launch.cmd
git commit -m "feat(terraform): Windows launcher"
```

---

## Task 6: Smoke-test terraform-ls end to end

This task proves the real server (for THIS host's platform) downloads,
extracts, and answers an LSP `initialize` when launched exactly as the IDE
would. It uses a temp dir so it does not pollute the plugin folder, then
verifies the launcher against a real binary placed where it expects.

**Files:**
- Create (temporary, not committed): `/tmp/tf-ls-smoke/`

- [ ] **Step 1: Determine this host's platform tuple**

Run:
```bash
case "$(uname -s)" in Darwin) OS=darwin;; Linux) OS=linux;; *) OS=linux;; esac
case "$(uname -m)" in x86_64|amd64) ARCH=amd64;; arm64|aarch64) ARCH=arm64;; *) ARCH=amd64;; esac
echo "${OS}_${ARCH}"
```
Expected: e.g. `darwin_arm64`. Note this value for the next steps.

- [ ] **Step 2: Download + extract the matching binary into the plugin's server dir**

Run (substitute the tuple from Step 1):
```bash
TUPLE=$(case "$(uname -s)" in Darwin) printf darwin;; *) printf linux;; esac)_$(case "$(uname -m)" in x86_64|amd64) printf amd64;; *) printf arm64;; esac)
mkdir -p "terraform/server/${TUPLE}"
curl -fsSL -o /tmp/tf-ls.zip "https://releases.hashicorp.com/terraform-ls/0.38.6/terraform-ls_0.38.6_${TUPLE}.zip"
unzip -o /tmp/tf-ls.zip -d "terraform/server/${TUPLE}"
ls -l "terraform/server/${TUPLE}/terraform-ls" && echo OK
```
Expected: lists the `terraform-ls` binary and prints `OK`.

- [ ] **Step 3: Verify the launcher starts the server and it answers initialize**

Run:
```bash
python3 - <<'PY'
import json, subprocess, os
def frame(obj):
    b = json.dumps(obj).encode()
    return f"Content-Length: {len(b)}\r\n\r\n".encode() + b
init = frame({"jsonrpc":"2.0","id":1,"method":"initialize",
              "params":{"processId":os.getpid(),"rootUri":None,"capabilities":{}}})
p = subprocess.Popen(["terraform/launch.sh"], stdin=subprocess.PIPE,
                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = p.communicate(input=init, timeout=30)
assert b'"capabilities"' in out, (out[:400], err[:400])
print("OK: server answered initialize")
PY
```
Expected: `OK: server answered initialize`

- [ ] **Step 4: Remove the downloaded binary so it is not committed**

Run: `rm -rf terraform/server && git status --porcelain terraform/ | grep -v 'server' ; echo cleaned`
Expected: `cleaned` and no `terraform/server` entries in git status.

- [ ] **Step 5: Confirm server dir is ignored / not staged**

Run: `git status --porcelain | grep 'terraform/server' && echo "LEAK" || echo OK`
Expected: `OK` (no server files staged — binaries must never be committed, per CONTRIBUTING §10).

---

## Task 7: README and top-level table

**Files:**
- Create: `terraform/README.md`
- Modify: `README.md` (add plugin table row)

- [ ] **Step 1: Write `terraform/README.md`**

```markdown
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
```

- [ ] **Step 2: Verify README renders the install tag pattern**

Run: `grep -q 'terraform-vX.Y.Z' terraform/README.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Add the plugin table row to top-level `README.md`**

Find this line in `README.md`:
```
| Java (jdtls) | [`java/`](./java) | `java-v0.1.0` |
```
Insert immediately after it:
```
| Terraform (terraform-ls) | [`terraform/`](./terraform) | `terraform-v0.1.0` |
```

- [ ] **Step 4: Verify the row is present**

Run: `grep -q 'Terraform (terraform-ls)' README.md && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add terraform/README.md README.md
git commit -m "docs(terraform): plugin README and table entry"
```

---

## Task 8: Final repo-wide validation

**Files:** none (verification only)

- [ ] **Step 1: All plugin JSON files parse**

Run:
```bash
for f in terraform/plugin.json terraform/grammar.json terraform/language-configuration.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK $f"
done
```
Expected: three `OK` lines.

- [ ] **Step 2: No binaries committed**

Run: `git ls-files terraform/ | grep -E '\.(zip|tar\.gz|exe)$|server/' && echo "LEAK" || echo OK`
Expected: `OK`

- [ ] **Step 3: Folder contains the required files**

Run: `ls terraform/ | sort | tr '\n' ' '`
Expected: `grammar.json language-configuration.json launch.cmd launch.sh plugin.json README.md`

- [ ] **Step 4: launch.sh is committed executable**

Run: `git ls-files -s terraform/launch.sh | grep -q '^100755' && echo OK || echo "NOT EXECUTABLE"`
Expected: `OK`

---

## Self-Review notes

- **Spec coverage:** language-configuration (Task 1), grammar (Task 2), manifest + 5 sha256 downloads (Task 3), POSIX launcher with uname selection + chmod + missing-binary error (Task 4), Windows launcher (Task 5), real terraform-ls smoke test (Task 6), README + top-level table (Task 7), no-binaries guard (Tasks 6, 8). All design sections map to a task.
- **Out of scope (per spec):** Windows arm64 launcher selection, `.tf.json`, bundling terraform CLI, platform-aware downloads.
- **Consistency:** platform tuple mapping (`darwin`/`linux`, `amd64`/`arm64`) is identical in the launcher (Task 4), the smoke test (Task 6), and the `server/<os>_<arch>` extractTo paths (Task 3).
