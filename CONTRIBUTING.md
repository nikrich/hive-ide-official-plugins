# Contributing to hive-ide-official-plugins

This guide is for two audiences:

- People **adding a plugin to this repo** (we'll review and merge,
  then tag a release on your behalf).
- People **writing their own plugin** published elsewhere — the shape
  is identical and the same rules apply.

If you read only one section: skip to §2 for the manifest schema,
then look at [`examples/hello-plugin/`](./examples/hello-plugin) for a
20-line plugin and [`java/`](./java) for one that bundles an external
language server.

---

## 1. What is a plugin?

A Hive IDE plugin is a **folder** containing a `plugin.json` manifest
plus assets it points at (grammars, language configs, launch scripts,
icons). That's it. There's no compiled code, no entry point, no
bundler.

Two things a plugin can do today:

1. **Register a language** — extension association, Monarch grammar,
   `LanguageConfiguration` (brackets, comments, auto-closing pairs).
   The editor (Monaco) renders the highlighting.
2. **Register a language server** — a command the IDE spawns over
   stdio that speaks LSP. The IDE handles wiring; the plugin just
   declares the launch.

Plugins **cannot** ship arbitrary executable JS that runs in the
renderer process. The only code that runs is the language-server
process you point `command` at, and that runs with the user's normal
shell privileges. See §11 for security implications.

---

## 2. Anatomy of `plugin.json`

The full schema, annotated:

```jsonc
{
  // Unique identifier — convention is "<publisher>/<name>".
  // Used as the install key. Two plugins with the same id can't
  // coexist in one workspace.
  "id": "your-org/cool-lang",

  // Human-readable name shown in the Plugins view.
  "name": "Cool Lang",

  // Semver. Bump on each release.
  "version": "0.3.1",

  "description": "Cool Lang syntax + LSP support",
  "publisher": "your-org",

  // Range of Hive IDE versions this plugin is known to work with.
  // The IDE warns on mismatch but still loads the plugin.
  "engines": { "hive": "^0.1.0" },

  "contributes": {
    "languages": [
      {
        // Language id used everywhere (model.getLanguageId() returns this).
        "id": "cool",
        // File extensions that auto-associate with this language.
        "extensions": [".cool", ".cl"],
        // Display names; first one is preferred.
        "aliases": ["Cool", "CoolLang"],
        // Path inside the plugin folder. Relative to plugin.json.
        "configuration": "./language-configuration.json",
        "grammar": "./grammar.json"
      }
    ],
    "languageServers": [
      {
        // Must match a language id declared above (or one declared
        // by another enabled plugin — but cross-plugin coupling is
        // discouraged).
        "language": "cool",

        // Launch command. Use the ${pluginDir} substitution to
        // refer to the plugin's installed folder. Do NOT hardcode
        // absolute paths.
        "command": "${pluginDir}/launch.sh",
        "args": ["--stdio"],

        // Only "stdio" supported in v1. (No TCP, no IPC.)
        "transport": "stdio",

        // Optional. Working directory for the spawned process.
        // ${pluginDir} substitution is also supported here.
        "cwd": "${pluginDir}",

        // Optional. Extra environment variables for the process.
        "env": {
          "COOL_LSP_LOG_LEVEL": "info"
        },

        // Optional. Passed verbatim into the LSP `initialize` request
        // as `initializationOptions`. Server-specific shape.
        "initializationOptions": {
          "settings": { "cool": { "format": { "indent": 2 } } }
        }
      }
    ]
  },

  // Optional. Assets the IDE will download on first enable.
  "setup": {
    "downloads": [
      {
        // https only. http URLs are rejected.
        "url": "https://example.com/cool-lsp-1.2.3.tar.gz",

        // Path inside the plugin folder where the archive contents land.
        // Relative to plugin.json.
        "extractTo": "./server",

        // Strongly recommended. Verified before extract; mismatch
        // aborts the install.
        "sha256": "0123abcd...",

        // "tar.gz" | "zip" | "none". "none" means copy the URL contents
        // to extractTo as-is (single file download).
        "archive": "tar.gz"
      }
    ]
  }
}
```

### `${pluginDir}` substitution

At launch time, the IDE expands `${pluginDir}` to the absolute path of
the plugin's installed folder on the user's machine. This is the only
substitution; there's no general templating engine. Use it in
`command`, `cwd`, and `args` strings.

Why this matters: your plugin folder lives at a different absolute
path on every user's machine (and inside the workspace, not where it
was installed from). `${pluginDir}` is the only stable way to refer to
your own bundled assets.

---

## 3. Adding a syntax-only plugin

Smallest viable plugin: one language id, one grammar, one config.

1. Pick a language id (lowercase, no spaces — `cool`).
2. Author `language-configuration.json` (Monaco
   [`LanguageConfiguration`](https://microsoft.github.io/monaco-editor/typedoc/interfaces/languages.LanguageConfiguration.html)
   shape):

   ```json
   {
     "comments": { "lineComment": "//", "blockComment": ["/*", "*/"] },
     "brackets": [["{", "}"], ["[", "]"], ["(", ")"]],
     "autoClosingPairs": [
       { "open": "{", "close": "}" },
       { "open": "\"", "close": "\"" }
     ]
   }
   ```

3. Author `grammar.json` (Monaco
   [Monarch](https://microsoft.github.io/monaco-editor/monarch.html)
   tokenizer). The canonical idiom for keyword tokenization is the
   `cases` block on the identifier rule:

   ```json
   {
     "defaultToken": "",
     "keywords": ["fn", "let", "return"],
     "tokenizer": {
       "root": [
         ["[a-zA-Z_][\\w]*", {
           "cases": {
             "@keywords": "keyword",
             "@default": "identifier"
           }
         }]
       ]
     }
   }
   ```

4. Wire both up in `plugin.json` under `contributes.languages[0]`.

See [`examples/hello-plugin/`](./examples/hello-plugin) for a working
17-line plugin you can copy.

---

## 4. Adding LSP support

Add a `contributes.languageServers[]` entry whose `language` matches a
language id you (or another plugin) registered. The IDE will spawn the
`command`, attach LSP over stdio, and route textDocument events for
buffers in that language.

```jsonc
{
  "contributes": {
    "languageServers": [{
      "language": "cool",
      "command": "${pluginDir}/server/bin/cool-lsp",
      "args": ["--stdio"],
      "transport": "stdio"
    }]
  }
}
```

**Transport.** Only `stdio` is supported in v1. The server reads LSP
messages on stdin and writes responses on stdout. stderr is captured
into the IDE's output panel.

**`initializationOptions`.** Server-specific; passed verbatim. Check
your server's docs for what it accepts.

**Restart semantics.** When the user toggles the plugin off → on, the
IDE shuts down the server cleanly via `shutdown` + `exit` and respawns
on next file open.

---

## 5. Bundling external assets via `setup.downloads`

Use this when your plugin needs a language server or large grammar
file that you don't want to commit to source control.

- **`url`** — https only.
- **`extractTo`** — relative to plugin folder. Created if missing.
- **`sha256`** — strongly recommended. Verified after download,
  before extraction.
- **`archive`** — `tar.gz` | `zip` | `none`.

Downloads run on **first enable**, not on install. Subsequent enables
re-use the cached extracted files. To force a re-download, the user
must uninstall + reinstall.

### When to skip `sha256`

If the upstream uses a redirecting mirror (e.g. Eclipse's
download.php), the resolved file may change. The Java plugin in this
repo intentionally omits `sha256` for that reason — note this in your
plugin's README. Strongly prefer hash-stable URLs when you have a
choice.

---

## 6. Cross-platform considerations

### Launch scripts

Ship **both** `launch.sh` (POSIX) and `launch.cmd` (Windows). Don't
rely on a shell being installed on Windows.

The IDE auto-picks based on the host OS — `*.cmd` on win32, `*.sh`
everywhere else — but only if you reference the bare name without
extension. Easier: be explicit in your manifest:

```json
"command": "${pluginDir}/launch.sh"
```

…and add a Windows-specific server entry guarded by your own platform
logic, or rely on the IDE picking the right one if you publish two
manifests (advanced — skip on v1).

For most plugins, write your bash launcher to be robust and rely on
WSL or Git Bash on Windows. Then ship a `.cmd` mirror as a courtesy.

### Path separators

Inside `plugin.json`, always use forward slashes: `./server/bin/x`.
The IDE normalizes them when invoking the OS.

### Finding the user's runtime

Don't hardcode `/usr/bin/python3` or `C:\Program Files\Java\jdk-21`.
Use `$PATH` lookups in your launcher:

```bash
PYTHON_BIN="$(command -v python3 || true)"
```

…and surface a friendly error to stderr if the runtime is missing.
The IDE shows stderr in the output panel.

---

## 7. Local development

While iterating on a plugin:

1. In the IDE, **Install → From folder…** and pick your plugin
   directory. The IDE **copies** the folder into the workspace's
   plugins directory.
2. To pick up changes:
   - **Grammar / language-configuration**: close and reopen the tab.
   - **LSP command / args**: disable + re-enable the plugin (this
     respawns the server).
   - **`plugin.json` shape** (new languages, new servers): uninstall
     and reinstall.
3. Tail stderr from your LSP via the IDE's output panel.

There's no hot-reload yet. Iteration is "edit → uninstall → reinstall
→ test".

---

## 8. Publishing a release

The release workflow in this repo (`.github/workflows/release.yml`)
ships a tarball of any top-level folder when you push a matching tag.

1. Bump `version` in your plugin's `plugin.json`.
2. Commit + push.
3. Tag with the pattern `<folder-name>-v<semver>` — e.g.
   `java-v0.1.0`, `python-v2.5.0`.
4. Push the tag: `git push origin java-v0.1.0`.
5. The workflow builds `java-0.1.0.tar.gz` (a gzipped tarball of the
   `java/` folder's contents — **not** the folder itself) and attaches
   it to a GitHub release named `java 0.1.0`.

Users install via the IDE's **Install → From GitHub** flow: owner,
repo, tag. The IDE downloads the matching tarball asset from the
release, verifies it parses as a plugin (has `plugin.json` at the
root), and installs.

### Publishing your own plugin elsewhere

The same tag-and-release flow works from any GitHub repo. Copy
`.github/workflows/release.yml` from this repo into yours. The
"Install → From GitHub" flow doesn't care that this repo is the
official one — it just wants `owner/repo` + a tag.

---

## 9. Versioning & engine compatibility

- **`version`** is semver. The IDE's update check (when implemented)
  uses it.
- **`engines.hive`** is a semver range. Common patterns:
  - `"^0.1.0"` — any 0.1.x. Use this in 0.x. The IDE treats 0.x
    minors as breaking.
  - `"^1.0.0"` — any 1.x. Use once the IDE stabilizes at 1.0.
  - `">=0.1.0 <0.3.0"` — explicit range, useful during migrations.

Mismatches show a warning in the Plugins view but don't block load.
If you make a breaking change to your plugin (e.g. renamed language
id), bump its major version.

---

## 10. Submitting a plugin to this repo

To add a plugin to `hive-ide-official-plugins`:

1. Open a PR adding a top-level folder named after your plugin
   (e.g. `python/`, `kotlin/`, `rust/`).
2. The folder must contain at minimum: `plugin.json`, `README.md`.
   Plus whatever grammar / config / launchers it needs.
3. Update the top-level [`README.md`](./README.md) plugin table.
4. **Don't commit binary blobs.** No `.jar`, no `.tar.gz` for the
   server itself. Use `setup.downloads` to pull them on first enable.
5. A reviewer will look at your launcher (§11) and merge. We'll cut
   the first release tag (`<folder>-v0.1.0`) on your behalf; after
   that you can push your own tags.

If you'd rather publish under your own GitHub org, that's fine — your
plugin doesn't need to live in this repo to work with the IDE.

---

## 11. Security & trust

Plugins run language servers **with the user's privileges**. A
malicious `launch.sh` can wipe a home directory, exfiltrate SSH keys,
or open a reverse shell. Three implications:

1. **Reviewers spot-check launchers.** PRs to this repo are reviewed
   for obvious badness — `curl … | sh`, hardcoded data exfil, etc.
   This is best-effort, not a security guarantee.
2. **The IDE does not sandbox plugin processes.** There's no AppArmor
   profile, no syscall filter, no `/tmp` jail.
3. **Users own the install decision.** "Install → From GitHub" prompts
   for the source repo + tag explicitly. Plugins from unknown sources
   should be treated like installing any other unsigned binary.

If you're a plugin author: write boring launchers. Use `set -euo
pipefail`. Don't `eval`. Don't `curl | sh`. Use `setup.downloads`
(with `sha256`) for binaries, not in-launcher fetches.

---

## See also

- [`examples/hello-plugin/`](./examples/hello-plugin) — minimum
  viable syntax-only plugin (~17 lines of JSON).
- [`java/`](./java) — full LSP plugin with `setup.downloads`,
  cross-platform launchers, and engine constraints.
- [Hive IDE source](https://github.com/nikrich/hive-ide) — REQ-006
  (plugin runtime) and REQ-007 (manifest schema) for the
  ground-truth contract this guide is written against.
