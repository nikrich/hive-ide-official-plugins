# Core 5 Language Plugins — Parallel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Five independent build streams (typescript, rust, cpp, csharp, go) run in parallel, one agent each in an isolated worktree + branch `feat/<lang>-plugin`. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship five language plugins (TypeScript/JS, Rust, C/C++, C#, Go) following the proven `python/` plugin pattern, each verified with a real LSP `initialize` smoke test, each on its own branch + PR.

**Architecture:** Each plugin is a folder of static files (manifest + grammar + language-config + two launchers + README). Servers download via `setup.downloads` (except Go). The launchers differ per plugin; everything else mirrors `python/`. Full server facts are in the spec: `docs/superpowers/specs/2026-06-05-core5-language-plugins-design.md`.

**Tech Stack:** JSON manifests, Monarch grammars, Monaco LanguageConfiguration, bash + cmd launchers; servers: typescript-language-server 5.3.0 + typescript 6.0.3, rust-analyzer 2026-06-01, clangd 22.1.0, OmniSharp-roslyn v1.39.15, gopls v0.22.0.

---

## Canonical template

`python/` is the reference. Copy its file shapes:
- `python/plugin.json` — manifest structure (id, name, version `0.1.0`, engines `^0.1.0`, contributes.languages, contributes.languageServers, setup.downloads).
- `python/language-configuration.json` — comments/brackets/autoClosingPairs/surroundingPairs.
- `python/launch.sh` — `set -euo pipefail`, `HERE=`, error-to-stderr idiom, `exec`.
- `python/launch.cmd` — `@echo off`, `where`, error idiom.
- `python/README.md` — sections: title, requirements, install (`<lang>-vX.Y.Z`), first-enable download note, features, troubleshooting, reporting bugs.
- `python/grammar.json` — Monarch shape (keywords/literals/tokenizer with `cases`).

Each plugin's `id` is `hive-ide-official-plugins/<lang>`. Each adds a top-level `README.md` table row after the Python row:
```
| Python (Pyright) | [`python/`](./python) | `python-v0.1.0` |
```

---

## Reusable LSP smoke-test harness

Use this Python harness (adjust the launcher path / extra readiness) to confirm a server answers `initialize`. It keeps stdin open and reads framed LSP messages until the id=1 response arrives.

```python
import json, subprocess, os, threading, sys
LAUNCHER = sys.argv[1] if len(sys.argv) > 1 else "./launch.sh"
def frame(o):
    b=json.dumps(o).encode(); return f"Content-Length: {len(b)}\r\n\r\n".encode()+b
init=frame({"jsonrpc":"2.0","id":1,"method":"initialize",
            "params":{"processId":os.getpid(),"rootUri":None,"capabilities":{}}})
p=subprocess.Popen([LAUNCHER], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
    for _ in range(15):
        b=rd(p.stdout)
        if b is None: break
        try: m=json.loads(b)
        except Exception: continue
        if m.get("id")==1 and "result" in m: res["r"]=m; return
t=threading.Thread(target=w, daemon=True); t.start(); t.join(timeout=40)
p.stdin.close()
try: p.wait(timeout=10)
except Exception: p.kill()
r=res.get("r")
if not (r and "capabilities" in r.get("result", {})):
    err = p.stderr.read()[:600] if p.stderr else b""
    raise SystemExit(f"FAIL: no initialize result. stderr={err!r}")
caps=sorted(k for k,v in r["result"]["capabilities"].items() if v)
print("OK: answered initialize. capabilities:", ", ".join(caps[:8]), "...")
```

**sha256 helper:** `shasum -a 256 <file> | awk '{print $1}'` → paste into the manifest entry's `sha256`.

---

## Per-stream tasks

Every stream follows the same checklist; only the parameters differ. The parameter blocks below are authoritative (verified upstream 2026-06-05).

### Common checklist (each plugin)

- [ ] **1.** Create branch `feat/<lang>-plugin` (own worktree).
- [ ] **2.** Create `<lang>/language-configuration.json` (adapt from python; per-language comment tokens below). Verify `python3 -m json.tool`. Commit.
- [ ] **3.** Create `<lang>/grammar.json` (keyword sets below). Verify JSON + that no Monarch `next:@state` references an undefined state. Commit.
- [ ] **4.** Create `<lang>/plugin.json` with the manifest + `setup.downloads` block below. Verify JSON + schema (single/multi download, https, sha256 64-hex once computed). Commit (sha256 filled in step 6).
- [ ] **5.** Create `<lang>/launch.sh` (verbatim below) + `<lang>/launch.cmd` (verbatim below). `chmod +x launch.sh`. `bash -n launch.sh`. Commit launch.sh as `100755`.
- [ ] **6.** Download this plugin's server artifact(s) for ALL platforms, compute each `sha256`, fill them into `plugin.json`. Commit the manifest update. (Go: skip — no downloads.)
- [ ] **7.** Smoke test: download the build-host artifact into `<lang>/server/...`, run `launch.sh` through the harness, confirm `initialize`. Then `rm -rf <lang>/server`. Confirm `git status` shows no `server/` staged.
- [ ] **8.** Create `<lang>/README.md` + add the top-level `README.md` table row. Commit.
- [ ] **9.** Final validation: JSON parses; no binaries tracked (`git ls-files <lang>/ | grep -E 'server/|\.(zip|gz|tgz|exe)$'` empty); folder has 6 files; launch.sh is `100755`. Push branch. Open PR titled `Add <Lang> plugin (<server>)`.

---

### Stream A: typescript

**language-configuration.json:** `lineComment` `//`, `blockComment` `["/*","*/"]`; brackets `{}[]()`; autoclose incl `"`,`'`,`` ` ``.

**grammar.json keywords:** `abstract,any,as,async,await,boolean,break,case,catch,class,const,continue,debugger,declare,default,delete,do,else,enum,export,extends,false,finally,for,from,function,get,if,implements,import,in,infer,instanceof,interface,is,keyof,let,namespace,never,new,null,number,object,of,private,protected,public,readonly,return,set,static,string,super,switch,symbol,this,throw,true,try,type,typeof,undefined,union,unknown,var,void,while,yield`. Line `//`, block `/* */`, double/single/template strings (template `` ` `` with `${}` → interpolation), decorators `@name`, numbers, `=>`.

**plugin.json languages:**
```json
"languages": [
  { "id": "typescript", "extensions": [".ts"], "aliases": ["TypeScript"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" },
  { "id": "typescriptreact", "extensions": [".tsx"], "aliases": ["TypeScript React"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" },
  { "id": "javascript", "extensions": [".js", ".mjs", ".cjs"], "aliases": ["JavaScript"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" },
  { "id": "javascriptreact", "extensions": [".jsx"], "aliases": ["JavaScript React"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" }
]
```
**languageServers:** one entry, `"language": "typescript"`, command `${pluginDir}/launch.sh`, args `[]`, transport `stdio`, cwd `${pluginDir}`. (One server entry; the IDE routes the registered ids to it.)

**setup.downloads (fill sha256 in step 6):**
```json
"downloads": [
  { "url": "https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-5.3.0.tgz", "extractTo": "./server/tls", "sha256": "<compute>", "archive": "tar.gz" },
  { "url": "https://registry.npmjs.org/typescript/-/typescript-6.0.3.tgz", "extractTo": "./server/ts", "sha256": "<compute>", "archive": "tar.gz" }
]
```

**launch.sh (verbatim):**
```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "Hive IDE TypeScript plugin: no 'node' binary found. typescript-language-server runs on Node.js — install Node 20+ and ensure 'node' is on PATH." >&2
  exit 1
fi

CLI="${HERE}/server/tls/package/lib/cli.mjs"
if [ ! -f "$CLI" ]; then
  echo "Hive IDE TypeScript plugin: server not found at ${CLI}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi

# tsserver wiring: the server resolves require('typescript') from a dir
# literally named 'typescript'. Point a symlink at the extracted package.
if [ ! -e "${HERE}/server/ts/typescript" ]; then
  ln -sfn package "${HERE}/server/ts/typescript"
fi

exec env NODE_PATH="${HERE}/server/ts" "$NODE_BIN" "$CLI" --stdio
```

**launch.cmd (verbatim):**
```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "NODE_BIN="
for /f "delims=" %%j in ('where node 2^>nul') do (
  if not defined NODE_BIN set "NODE_BIN=%%j"
)
if not defined NODE_BIN (
  echo Hive IDE TypeScript plugin: no 'node' binary found. Install Node 20+ and ensure 'node' is on PATH. 1>&2
  exit /b 1
)

set "CLI=%HERE%\server\tls\package\lib\cli.mjs"
if not exist "%CLI%" (
  echo Hive IDE TypeScript plugin: server not found at %CLI%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

if not exist "%HERE%\server\ts\typescript" (
  mklink /J "%HERE%\server\ts\typescript" "%HERE%\server\ts\package" >nul 2>&1
)

set "NODE_PATH=%HERE%\server\ts"
"%NODE_BIN%" "%CLI%" --stdio
```

**Smoke test:** extract both tarballs into `typescript/server/tls` and `typescript/server/ts` (each yields `package/`), then run harness on `typescript/launch.sh`. Requires Node 20+ on the build host. Expect capabilities incl `completionProvider`, `definitionProvider`, `hoverProvider`.

**README requirements:** Node.js 20+ on PATH (required). Recommend opening a project so tsserver resolves project config.

---

### Stream B: rust

**language-configuration.json:** `lineComment` `//`, `blockComment` `["/*","*/"]`; brackets; autoclose incl `"`.

**grammar.json keywords:** `as,async,await,break,const,continue,crate,dyn,else,enum,extern,false,fn,for,if,impl,in,let,loop,match,mod,move,mut,pub,ref,return,self,Self,static,struct,super,trait,true,type,unsafe,use,where,while`. Plus attributes `#[...]`/`#![...]` as `tag`, lifetimes `'[a-z]+` as `type`, macros `[a-z_]+!` as `keyword`, `//`/`/* */` (nestable), strings with escapes, numbers (incl `0x`/`0b`/suffixes), `::`.

**plugin.json languages:** one — `{ "id": "rust", "extensions": [".rs"], "aliases": ["Rust"], ... }`. One server entry `"language": "rust"`.

**setup.downloads (fill sha256 in step 6; note `none` for `.gz`):**
```json
"downloads": [
  { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/rust-analyzer-aarch64-apple-darwin.gz", "extractTo": "./server/darwin_arm64", "sha256": "<compute>", "archive": "none" },
  { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/rust-analyzer-x86_64-apple-darwin.gz", "extractTo": "./server/darwin_amd64", "sha256": "<compute>", "archive": "none" },
  { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/rust-analyzer-x86_64-unknown-linux-gnu.gz", "extractTo": "./server/linux_amd64", "sha256": "<compute>", "archive": "none" },
  { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/rust-analyzer-aarch64-unknown-linux-gnu.gz", "extractTo": "./server/linux_arm64", "sha256": "<compute>", "archive": "none" },
  { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2026-06-01/rust-analyzer-x86_64-pc-windows-msvc.zip", "extractTo": "./server/windows_amd64", "sha256": "<compute>", "archive": "zip" }
]
```
For `archive: none`, the file lands at `extractTo/<basename>` (e.g. `server/darwin_arm64/rust-analyzer-aarch64-apple-darwin.gz`).

**launch.sh (verbatim):**
```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)      OS="linux" ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             ARCH="amd64" ;;
esac

DIR="${HERE}/server/${OS}_${ARCH}"
BIN="${DIR}/rust-analyzer"

# Unix assets ship as a single gzipped binary; decompress on first run.
if [ ! -f "$BIN" ]; then
  GZ="$(ls "${DIR}/"*.gz 2>/dev/null | head -1 || true)"
  if [ -n "$GZ" ]; then
    gunzip -c "$GZ" > "$BIN"
    chmod +x "$BIN"
  fi
fi

if [ ! -f "$BIN" ]; then
  echo "Hive IDE Rust plugin: rust-analyzer binary for ${OS}_${ARCH} not found in ${DIR}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"

exec "$BIN"
```

**launch.cmd (verbatim):**
```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\rust-analyzer.exe"
if not exist "%BIN%" (
  echo Hive IDE Rust plugin: rust-analyzer.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%BIN%"
```

**Smoke test:** download the host `.gz` into `rust/server/<tuple>/`, run harness on `rust/launch.sh` (it gunzips + runs). rust-analyzer answers `initialize` even without a Rust toolchain. Expect `definitionProvider`, `completionProvider`, `hoverProvider`.

**README requirements:** none to start; a Rust toolchain (rustup/cargo) on PATH recommended for full analysis. Note weekly release cadence (pinned `2026-06-01`).

---

### Stream C: cpp

**language-configuration.json:** `lineComment` `//`, `blockComment` `["/*","*/"]`; brackets; autoclose incl `"`,`'`.

**grammar.json keywords:** C/C++ — `alignas,auto,bool,break,case,catch,char,class,const,constexpr,continue,decltype,default,delete,do,double,else,enum,explicit,export,extern,false,float,for,friend,goto,if,inline,int,long,mutable,namespace,new,noexcept,nullptr,operator,private,protected,public,register,return,short,signed,sizeof,static,struct,switch,template,this,throw,true,try,typedef,typename,union,unsigned,using,virtual,void,volatile,while`. Preprocessor lines `#\s*\w+` as `keyword.directive` (handle `#include <...>`/`"..."`), `//`/`/* */`, char/string literals with escapes, numbers, `::`.

**plugin.json languages:** two —
```json
"languages": [
  { "id": "c", "extensions": [".c", ".h"], "aliases": ["C"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" },
  { "id": "cpp", "extensions": [".cpp", ".cc", ".cxx", ".c++", ".hpp", ".hh", ".hxx", ".h++"], "aliases": ["C++"], "configuration": "./language-configuration.json", "grammar": "./grammar.json" }
]
```
**languageServers:** one entry `"language": "cpp"` (clangd handles both; the IDE routes `c` files too via the shared server — if the IDE requires per-id servers, add a second identical entry with `"language": "c"`).

**setup.downloads (3 platforms only):**
```json
"downloads": [
  { "url": "https://github.com/clangd/clangd/releases/download/22.1.0/clangd-mac-22.1.0.zip", "extractTo": "./server/mac", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/clangd/clangd/releases/download/22.1.0/clangd-linux-22.1.0.zip", "extractTo": "./server/linux_amd64", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/clangd/clangd/releases/download/22.1.0/clangd-windows-22.1.0.zip", "extractTo": "./server/windows_amd64", "sha256": "<compute>", "archive": "zip" }
]
```
Binary inside each zip: `clangd_22.1.0/bin/clangd` (`.exe` on Windows).

**launch.sh (verbatim):**
```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) DIR="${HERE}/server/mac" ;;
  Linux)
    case "$(uname -m)" in
      x86_64|amd64) DIR="${HERE}/server/linux_amd64" ;;
      *) echo "Hive IDE C/C++ plugin: clangd has no Linux-$(uname -m) build upstream. Install clangd via your package manager and use it directly." >&2; exit 1 ;;
    esac ;;
  *) DIR="${HERE}/server/linux_amd64" ;;
esac

BIN="${DIR}/clangd_22.1.0/bin/clangd"
if [ ! -f "$BIN" ]; then
  echo "Hive IDE C/C++ plugin: clangd not found at ${BIN}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"
# Strip macOS quarantine so the unsigned binary starts without a prompt.
[ "$(uname -s)" = "Darwin" ] && xattr -dr com.apple.quarantine "$DIR" 2>/dev/null || true

exec "$BIN" --background-index
```

**launch.cmd (verbatim):**
```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\clangd_22.1.0\bin\clangd.exe"
if not exist "%BIN%" (
  echo Hive IDE C/C++ plugin: clangd.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%BIN%" --background-index
```

**Smoke test:** download the host zip (mac → `cpp/server/mac`, linux x64 → `cpp/server/linux_amd64`), extract, run harness on `cpp/launch.sh`. clangd answers `initialize` without compile_commands.json. Expect `completionProvider`, `definitionProvider`, `hoverProvider`.

**README requirements:** none. `compile_commands.json` (CMake `CMAKE_EXPORT_COMPILE_COMMANDS=ON`, or Bear) recommended for full features. Note: no Linux-arm64 build.

---

### Stream D: csharp

**language-configuration.json:** `lineComment` `//`, `blockComment` `["/*","*/"]`; brackets; autoclose incl `"`,`'`.

**grammar.json keywords:** `abstract,as,async,await,base,bool,break,byte,case,catch,char,checked,class,const,continue,decimal,default,delegate,do,double,else,enum,event,explicit,extern,false,finally,fixed,float,for,foreach,get,goto,if,implicit,in,int,interface,internal,is,lock,long,namespace,new,null,object,operator,out,override,params,private,protected,public,readonly,ref,return,sbyte,sealed,set,short,sizeof,stackalloc,static,string,struct,switch,this,throw,true,try,typeof,uint,ulong,ushort,using,var,virtual,void,volatile,while`. `//`/`/* */`, strings incl `$"..."` interpolation and verbatim `@"..."`, attributes `[...]` as `tag`, numbers.

**plugin.json languages:** one — `{ "id": "csharp", "extensions": [".cs", ".csx"], "aliases": ["C#"], ... }`. One server entry `"language": "csharp"`.

**setup.downloads (5 platforms, ~48MB each):**
```json
"downloads": [
  { "url": "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/omnisharp-osx-arm64-net6.0.zip", "extractTo": "./server/darwin_arm64", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/omnisharp-osx-x64-net6.0.zip", "extractTo": "./server/darwin_amd64", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/omnisharp-linux-x64-net6.0.zip", "extractTo": "./server/linux_amd64", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/omnisharp-linux-arm64-net6.0.zip", "extractTo": "./server/linux_arm64", "sha256": "<compute>", "archive": "zip" },
  { "url": "https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.15/omnisharp-win-x64-net6.0.zip", "extractTo": "./server/windows_amd64", "sha256": "<compute>", "archive": "zip" }
]
```
Executable at archive root: `OmniSharp` / `OmniSharp.exe`.

**launch.sh (verbatim):**
```bash
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)      OS="linux" ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             ARCH="amd64" ;;
esac

DIR="${HERE}/server/${OS}_${ARCH}"
BIN="${DIR}/OmniSharp"
if [ ! -f "$BIN" ]; then
  echo "Hive IDE C# plugin: OmniSharp binary for ${OS}_${ARCH} not found in ${DIR}. The setup download may have failed; toggle the plugin off and on to retry." >&2
  exit 1
fi
[ -x "$BIN" ] || chmod +x "$BIN"
[ "$(uname -s)" = "Darwin" ] && xattr -dr com.apple.quarantine "$DIR" 2>/dev/null || true

if ! command -v dotnet >/dev/null 2>&1; then
  echo "Hive IDE C# plugin: '.NET runtime' not found. OmniSharp needs the .NET 6+ runtime — install it from https://dotnet.microsoft.com/download and ensure 'dotnet' is on PATH." >&2
  exit 1
fi

exec "$BIN" -lsp -s "${PWD}"
```

**launch.cmd (verbatim):**
```bat
@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\OmniSharp.exe"
if not exist "%BIN%" (
  echo Hive IDE C# plugin: OmniSharp.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

where dotnet >nul 2>&1
if errorlevel 1 (
  echo Hive IDE C# plugin: 'dotnet' not found. Install the .NET 6+ runtime from https://dotnet.microsoft.com/download and ensure it is on PATH. 1>&2
  exit /b 1
)

"%BIN%" -lsp -s "%CD%"
```

**Smoke test (needs `dotnet` on the build host):** download the host zip, extract, run harness on `csharp/launch.sh`. Expect OmniSharp to answer `initialize` (may take several seconds to start). If `dotnet` is NOT installed on the build machine, report BLOCKED on smoke test (do not claim verified) — still complete files + sha256 + push.

**README requirements:** .NET 6+ runtime on PATH (`dotnet`). Note large one-time download (~240MB across platforms) and that a project/solution gives best results.

---

### Stream E: go

**language-configuration.json:** `lineComment` `//`, `blockComment` `["/*","*/"]`; brackets; autoclose incl `"`,`` ` ``.

**grammar.json keywords:** `break,case,chan,const,continue,default,defer,else,fallthrough,for,func,go,goto,if,import,interface,map,package,range,return,select,struct,switch,type,var`; types `bool,byte,complex64,complex128,error,float32,float64,int,int8,int16,int32,int64,rune,string,uint,uint8,uint16,uint32,uint64,uintptr`; literals `true,false,nil,iota`. `//`/`/* */`, interpreted `"..."` and raw `` `...` `` strings, runes, numbers.

**plugin.json languages:** one — `{ "id": "go", "extensions": [".go"], "aliases": ["Go"], ... }`. One server entry `"language": "go"`, command `${pluginDir}/launch.sh`, args `[]`, transport `stdio`. **Omit `cwd`** (let the IDE default to the workspace root; gopls needs the project root, not pluginDir). **No `setup` block.**

**launch.sh (verbatim):**
```bash
#!/usr/bin/env bash
set -euo pipefail

GOPLS="$(command -v gopls || true)"
if [ -z "$GOPLS" ]; then
  CAND="${GOPATH:-$HOME/go}/bin/gopls"
  [ -x "$CAND" ] && GOPLS="$CAND"
fi

if [ -z "$GOPLS" ]; then
  if command -v go >/dev/null 2>&1; then
    echo "Hive IDE Go plugin: 'gopls' not found. Install it with: go install golang.org/x/tools/gopls@latest" >&2
  else
    echo "Hive IDE Go plugin: 'gopls' and the Go toolchain are not installed. Install Go from https://go.dev/dl/ then run: go install golang.org/x/tools/gopls@latest" >&2
  fi
  exit 1
fi

exec "$GOPLS" serve
```

**launch.cmd (verbatim):**
```bat
@echo off
setlocal

set "GOPLS="
for /f "delims=" %%j in ('where gopls 2^>nul') do (
  if not defined GOPLS set "GOPLS=%%j"
)
if not defined GOPLS (
  if exist "%USERPROFILE%\go\bin\gopls.exe" set "GOPLS=%USERPROFILE%\go\bin\gopls.exe"
)
if not defined GOPLS (
  echo Hive IDE Go plugin: 'gopls' not found. Install Go from https://go.dev/dl/ then run: go install golang.org/x/tools/gopls@latest 1>&2
  exit /b 1
)

"%GOPLS%" serve
```

**Smoke test:** ensure `gopls` is available on the build host (if absent, run `go install golang.org/x/tools/gopls@latest` as build-host setup), then run harness on `go/launch.sh`. Expect `definitionProvider`, `completionProvider`, `hoverProvider`. No `server/` dir is created (nothing committed to clean up).

**README requirements:** Go toolchain + gopls on PATH (`go install golang.org/x/tools/gopls@latest`). Explain the two-step prereq and the `~/go/bin` PATH gotcha.

---

## Self-Review notes

- **Spec coverage:** every plugin in the spec has a stream (A–E) with its verified download block, launch.sh/launch.cmd, grammar keywords, and smoke test. The shared template (python/) covers grammar/config/README shape. Top-level table row in step 8. No-binary guard in steps 7 & 9.
- **Consistency:** server paths in each launcher match that plugin's `extractTo` (`server/tls`+`server/ts` for ts; `server/<tuple>` for rust/csharp; `server/mac|linux_amd64|windows_amd64/clangd_22.1.0/bin/clangd` for cpp; none for go). Versions pinned identically in spec and plan (ts 5.3.0/6.0.3, rust 2026-06-01, clangd 22.1.0, omnisharp v1.39.15, gopls v0.22.0).
- **Known build-host dependencies:** ts needs Node 20+, csharp needs dotnet, go needs gopls (installable). cpp/rust need nothing. A stream whose runtime is absent on the build host completes files + sha256 + push but reports the smoke test as BLOCKED rather than verified.
- **Out of scope:** bundling runtimes, clangd linux-arm64, deep JSX/interpolation grammar, DAP.
