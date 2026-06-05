# Python Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `python/` plugin to hive-ide-official-plugins giving Hive IDE Python syntax highlighting plus full LSP features via Microsoft's Pyright.

**Architecture:** A folder-only plugin (no compiled code) following the `java/`/`terraform/` pattern: a `plugin.json` manifest registers the `python` language + a stdio language server, a single `setup.downloads` entry fetches the Pyright npm tarball on first enable (one cross-platform JS bundle — no per-platform binaries), and cross-platform launchers locate Node on PATH and run the bundled langserver over stdio.

**Tech Stack:** JSON manifest (hive plugin schema), Monarch grammar, Monaco LanguageConfiguration, POSIX `bash` + Windows `cmd` launchers, Node.js (user-provided), Pyright 1.1.410.

---

## File Structure

```
python/
  plugin.json                  # manifest: language + LSP + 1 download (pyright npm tarball)
  grammar.json                 # Python Monarch tokenizer
  language-configuration.json  # comments, brackets, auto-close
  launch.sh                    # POSIX: locate node -> node server/package/langserver.index.js --stdio
  launch.cmd                   # Windows: same via where node
  README.md                    # install, requirements, features, troubleshooting
```
Plus one edit to the top-level `README.md` (plugin table row).

Reference files (read, don't modify): `terraform/plugin.json`, `terraform/launch.sh`, `terraform/launch.cmd`, `java/launch.sh`, `CONTRIBUTING.md`.

Verified facts (Pyright 1.1.410, npm distribution):
- Download URL: `https://registry.npmjs.org/pyright/-/pyright-1.1.410.tgz`
- sha256 of tarball: `4d6b7a25f9617ea8ff7b2e98cd87c146d132a95cbfb29bf58bd638018a76ac48`
- Tarball extracts to `package/`; langserver entry is `package/langserver.index.js`
- Run as: `node <…>/server/package/langserver.index.js --stdio` (smoke-tested: answers LSP `initialize`)
- Requires Node.js on PATH.

---

## Task 1: Language configuration

**Files:**
- Create: `python/language-configuration.json`

- [ ] **Step 1: Write the file**

```json
{
  "comments": {
    "lineComment": "#"
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
    { "open": "'", "close": "'", "notIn": ["string", "comment"] }
  ],
  "surroundingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"" },
    { "open": "'", "close": "'" }
  ]
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool python/language-configuration.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add python/language-configuration.json
git commit -m "feat(python): language configuration"
```

---

## Task 2: Python grammar

**Files:**
- Create: `python/grammar.json`

- [ ] **Step 1: Write the file**

```json
{
  "defaultToken": "",
  "tokenPostfix": ".python",
  "keywords": [
    "and", "as", "assert", "async", "await", "break", "case", "class",
    "continue", "def", "del", "elif", "else", "except", "finally", "for",
    "from", "global", "if", "import", "in", "is", "lambda", "match",
    "nonlocal", "not", "or", "pass", "raise", "return", "try", "while",
    "with", "yield"
  ],
  "literals": ["True", "False", "None"],
  "builtins": [
    "print", "len", "range", "int", "str", "float", "bool", "list",
    "dict", "set", "tuple", "self", "super", "isinstance", "Exception",
    "open", "enumerate", "zip", "map", "filter", "type", "object"
  ],
  "brackets": [
    { "open": "{", "close": "}", "token": "delimiter.curly" },
    { "open": "[", "close": "]", "token": "delimiter.square" },
    { "open": "(", "close": ")", "token": "delimiter.parenthesis" }
  ],
  "tokenizer": {
    "root": [
      ["@\\s*[a-zA-Z_]\\w*", "tag"],
      ["[a-zA-Z_]\\w*", {
        "cases": {
          "@keywords": "keyword",
          "@literals": "keyword.literal",
          "@builtins": "type.identifier",
          "@default": "identifier"
        }
      }],
      { "include": "@whitespace" },
      { "include": "@numbers" },
      { "include": "@strings" },
      ["[{}()\\[\\]]", "@brackets"],
      ["[;,.]", "delimiter"],
      ["[=><!~?:&|+\\-*/^%]+", "operator"]
    ],
    "whitespace": [
      ["[ \\t\\r\\n]+", "white"],
      ["#.*$", "comment"]
    ],
    "numbers": [
      ["0[xX][0-9a-fA-F_]+", "number.hex"],
      ["0[bB][01_]+", "number.binary"],
      ["\\d[\\d_]*\\.\\d[\\d_]*([eE][\\-+]?\\d+)?[jJ]?", "number.float"],
      ["\\d[\\d_]*([eE][\\-+]?\\d+)?[jJ]?", "number"]
    ],
    "strings": [
      ["[bBfFrRuU]*\"\"\"", { "token": "string.quote", "next": "@tdqstring" }],
      ["[bBfFrRuU]*'''", { "token": "string.quote", "next": "@tsqstring" }],
      ["[bBfFrRuU]*\"", { "token": "string.quote", "next": "@dqstring" }],
      ["[bBfFrRuU]*'", { "token": "string.quote", "next": "@sqstring" }]
    ],
    "tdqstring": [
      ["[^\"]+", "string"],
      ["\"\"\"", { "token": "string.quote", "next": "@pop" }],
      ["\"", "string"]
    ],
    "tsqstring": [
      ["[^']+", "string"],
      ["'''", { "token": "string.quote", "next": "@pop" }],
      ["'", "string"]
    ],
    "dqstring": [
      ["[^\\\\\"]+", "string"],
      ["\\\\.", "string.escape"],
      ["\"", { "token": "string.quote", "next": "@pop" }],
      ["$", "string", "@pop"]
    ],
    "sqstring": [
      ["[^\\\\']+", "string"],
      ["\\\\.", "string.escape"],
      ["'", { "token": "string.quote", "next": "@pop" }],
      ["$", "string", "@pop"]
    ]
  }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool python/grammar.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify no Monarch state is referenced but undefined**

Run:
```bash
python3 - <<'PY'
import json, re
g = json.load(open("python/grammar.json"))
states = set(g["tokenizer"].keys())
refs = set()
def walk(x):
    if isinstance(x, str):
        for m in re.findall(r'"?next"?\s*:?\s*"@(\w+)"', x):
            refs.add(m)
    elif isinstance(x, list):
        for i in x: walk(i)
    elif isinstance(x, dict):
        for k, v in x.items():
            if k == "next" and isinstance(v, str) and v.startswith("@"):
                refs.add(v[1:])
            walk(v)
walk(g["tokenizer"])
# @pop / @push are engine builtins, not states
refs.discard("pop"); refs.discard("push")
missing = refs - states
assert not missing, f"undefined states referenced: {missing}"
print("OK states:", sorted(states))
PY
```
Expected: `OK states: [...]` with no assertion error. (The `next` targets used are `tdqstring`, `tsqstring`, `dqstring`, `sqstring`, all defined.)

- [ ] **Step 4: Commit**

```bash
git add python/grammar.json
git commit -m "feat(python): Python Monarch grammar"
```

---

## Task 3: plugin.json manifest

**Files:**
- Create: `python/plugin.json`

- [ ] **Step 1: Write the file**

```json
{
  "id": "hive-ide-official-plugins/python",
  "name": "Python",
  "version": "0.1.0",
  "description": "Python language support via Pyright (Microsoft). Bundles the language server; requires Node.js 18+ on PATH.",
  "publisher": "hive-ide-official-plugins",
  "engines": {
    "hive": "^0.1.0"
  },
  "contributes": {
    "languages": [
      {
        "id": "python",
        "extensions": [
          ".py",
          ".pyi"
        ],
        "aliases": [
          "Python"
        ],
        "configuration": "./language-configuration.json",
        "grammar": "./grammar.json"
      }
    ],
    "languageServers": [
      {
        "language": "python",
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
        "url": "https://registry.npmjs.org/pyright/-/pyright-1.1.410.tgz",
        "extractTo": "./server",
        "sha256": "4d6b7a25f9617ea8ff7b2e98cd87c146d132a95cbfb29bf58bd638018a76ac48",
        "archive": "tar.gz"
      }
    ]
  }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `python3 -m json.tool python/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify schema-critical fields**

Run:
```bash
python3 - <<'PY'
import json
m = json.load(open("python/plugin.json"))
assert m["id"] == "hive-ide-official-plugins/python"
lang = m["contributes"]["languages"][0]
assert lang["id"] == "python"
assert lang["extensions"] == [".py", ".pyi"]
srv = m["contributes"]["languageServers"][0]
assert srv["language"] == "python"
assert srv["transport"] == "stdio"
assert srv["command"] == "${pluginDir}/launch.sh"
dls = m["setup"]["downloads"]
assert len(dls) == 1
d = dls[0]
assert d["url"] == "https://registry.npmjs.org/pyright/-/pyright-1.1.410.tgz"
assert d["url"].startswith("https://")
assert d["archive"] == "tar.gz"
assert len(d["sha256"]) == 64
assert d["extractTo"] == "./server"
print("OK manifest")
PY
```
Expected: `OK manifest`

- [ ] **Step 4: Commit**

```bash
git add python/plugin.json
git commit -m "feat(python): plugin manifest with Pyright 1.1.410 download"
```

---

## Task 4: POSIX launcher

**Files:**
- Create: `python/launch.sh`

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Locate node.
NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "Hive IDE Python plugin: no 'node' binary found. Pyright runs on Node.js — install Node 18+ and ensure 'node' is on PATH." >&2
  exit 1
fi

SERVER="${HERE}/server/package/langserver.index.js"
if [ ! -f "$SERVER" ]; then
  echo "Hive IDE Python plugin: Pyright server not found at ${SERVER}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

exec "$NODE_BIN" "$SERVER" --stdio
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x python/launch.sh && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify bash syntax**

Run: `bash -n python/launch.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Verify the missing-server error path fires cleanly (server not present yet)**

Run: `python/launch.sh; echo "exit=$?"`
Expected: a stderr line containing `Pyright server not found` and `exit=1` (node is present but the server dir isn't, so it takes the second error branch). If node is NOT installed on this machine, expect the `no 'node' binary` message and `exit=1` instead — either is acceptable.

- [ ] **Step 5: Commit**

```bash
git add python/launch.sh
git commit -m "feat(python): POSIX launcher locating node"
```

---

## Task 5: Windows launcher

**Files:**
- Create: `python/launch.cmd`

- [ ] **Step 1: Write the file**

```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

rem Locate node.
set "NODE_BIN="
for /f "delims=" %%j in ('where node 2^>nul') do (
  if not defined NODE_BIN set "NODE_BIN=%%j"
)
if not defined NODE_BIN (
  echo Hive IDE Python plugin: no 'node' binary found. Pyright runs on Node.js - install Node 18+ and ensure 'node' is on PATH. 1>&2
  exit /b 1
)

set "SERVER=%HERE%\server\package\langserver.index.js"
if not exist "%SERVER%" (
  echo Hive IDE Python plugin: Pyright server not found at %SERVER%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%NODE_BIN%" "%SERVER%" --stdio
```

- [ ] **Step 2: Verify it references the correct server path and node lookup**

Run: `grep -q 'server\\\\package\\\\langserver.index.js' python/launch.cmd && grep -q 'where node' python/launch.cmd && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add python/launch.cmd
git commit -m "feat(python): Windows launcher"
```

---

## Task 6: Smoke-test Pyright end to end

Proves the real server downloads, extracts, and answers an LSP
`initialize` when launched exactly as the IDE would (via `launch.sh`).
Requires `node` on this machine.

**Files:** none committed (downloads into `python/server/`, removed after).

- [ ] **Step 1: Confirm node is available**

Run: `node --version && echo "NODE OK"`
Expected: a version string and `NODE OK`. (If node is absent, install Node 18+ first — the smoke test cannot run without it.)

- [ ] **Step 2: Download + extract Pyright into the plugin's server dir**

Run:
```bash
mkdir -p python/server
curl -fsSL -o /tmp/pyright.tgz "https://registry.npmjs.org/pyright/-/pyright-1.1.410.tgz"
# Verify the sha256 matches the manifest before trusting it.
GOT=$(shasum -a 256 /tmp/pyright.tgz | awk '{print $1}')
[ "$GOT" = "4d6b7a25f9617ea8ff7b2e98cd87c146d132a95cbfb29bf58bd638018a76ac48" ] && echo "SHA OK" || { echo "SHA MISMATCH: $GOT"; exit 1; }
tar -xzf /tmp/pyright.tgz -C python/server
ls python/server/package/langserver.index.js && echo "EXTRACT OK"
```
Expected: `SHA OK`, the langserver path listed, and `EXTRACT OK`.

- [ ] **Step 3: Verify the launcher starts the server and it answers initialize**

Run:
```bash
python3 - <<'PY'
import json, subprocess, os, threading
def frame(o):
    b=json.dumps(o).encode(); return f"Content-Length: {len(b)}\r\n\r\n".encode()+b
init=frame({"jsonrpc":"2.0","id":1,"method":"initialize",
            "params":{"processId":os.getpid(),"rootUri":None,"capabilities":{}}})
p=subprocess.Popen(["python/launch.sh"], stdin=subprocess.PIPE,
                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
p.stdin.write(init); p.stdin.flush()
def rd(f):
    h={}
    while True:
        l=f.readline()
        if not l: return None
        if l in (b"\r\n", b"\n"): break
        k,_,v=l.decode().partition(":"); h[k.strip().lower()]=v.strip()
    return f.read(int(h["content-length"]))
res={}
def w():
    for _ in range(10):
        b=rd(p.stdout)
        if b is None: break
        msg=json.loads(b)
        if msg.get("id")==1 and "result" in msg: res["r"]=msg; return
t=threading.Thread(target=w, daemon=True); t.start(); t.join(timeout=30)
p.stdin.close()
try: p.wait(timeout=10)
except Exception: p.kill()
r=res.get("r")
assert r and "capabilities" in r["result"], ("no initialize result", res)
print("OK: Pyright answered initialize (id=1) with capabilities")
PY
```
Expected: `OK: Pyright answered initialize (id=1) with capabilities`

- [ ] **Step 4: Remove the downloaded server so it is not committed**

Run: `rm -rf python/server && echo cleaned`
Expected: `cleaned`

- [ ] **Step 5: Confirm nothing under server/ is staged**

Run: `git status --porcelain | grep 'python/server' && echo "LEAK" || echo OK`
Expected: `OK` (binaries/server bundle must never be committed, per CONTRIBUTING §10).

---

## Task 7: README and top-level table

**Files:**
- Create: `python/README.md`
- Modify: `README.md` (add plugin table row)

- [ ] **Step 1: Write `python/README.md`**

```markdown
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
```

- [ ] **Step 2: Verify README mentions Node requirement and install tag**

Run: `grep -q 'Node.js 18+' python/README.md && grep -q 'python-vX.Y.Z' python/README.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Add the plugin table row to top-level `README.md`**

Find this line in `README.md`:
```
| Terraform (terraform-ls) | [`terraform/`](./terraform) | `terraform-v0.1.0` |
```
Insert immediately after it:
```
| Python (Pyright) | [`python/`](./python) | `python-v0.1.0` |
```

- [ ] **Step 4: Verify the row is present**

Run: `grep -q 'Python (Pyright)' README.md && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add python/README.md README.md
git commit -m "docs(python): plugin README and table entry"
```

---

## Task 8: Final repo-wide validation

**Files:** none (verification only)

- [ ] **Step 1: All plugin JSON files parse**

Run:
```bash
for f in python/plugin.json python/grammar.json python/language-configuration.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK $f"
done
```
Expected: three `OK` lines.

- [ ] **Step 2: No server bundle / binaries committed**

Run: `git ls-files python/ | grep -E 'server/|\.tgz$|\.js$' && echo "LEAK" || echo OK`
Expected: `OK`

- [ ] **Step 3: Folder contains the required files**

Run: `ls python/ | sort | tr '\n' ' '`
Expected: `grammar.json language-configuration.json launch.cmd launch.sh plugin.json README.md`

- [ ] **Step 4: launch.sh is committed executable**

Run: `git ls-files -s python/launch.sh | grep -q '^100755' && echo OK || echo "NOT EXECUTABLE"`
Expected: `OK`

---

## Self-Review notes

- **Spec coverage:** language-configuration (Task 1), grammar with Python keywords/builtins/strings/decorators (Task 2), manifest with single sha256-pinned npm download (Task 3), POSIX launcher locating node + both error paths (Task 4), Windows launcher (Task 5), real Pyright smoke test incl. sha256 verification (Task 6), README with Node requirement + interpreter note + top-level table (Task 7), no-bundle-committed guard (Tasks 6, 8). All design sections map to a task.
- **Out of scope (per spec):** bundling Node/Python, debugging, f-string interpolation tokenizing, `.ipynb`.
- **Consistency:** the server path `server/package/langserver.index.js` is identical in the launcher (Task 4), Windows launcher (Task 5), the smoke test (Task 6), and matches `extractTo: ./server` + the tarball's `package/` root (Task 3). The sha256 `4d6b...ac48` is identical in the manifest (Task 3) and the smoke-test verification (Task 6).
