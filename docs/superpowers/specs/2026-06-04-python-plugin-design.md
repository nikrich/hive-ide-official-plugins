# Python plugin — design

**Date:** 2026-06-04
**Status:** Approved

## Goal

Add a `python/` plugin to `hive-ide-official-plugins` giving Hive IDE full
Python language support: syntax highlighting plus LSP features
(type-aware diagnostics, completion, hover, go-to-definition, find
references, document symbols) via Microsoft's **Pyright**.

It follows the existing `java/`/`terraform/` plugin pattern (an LSP plugin
that bundles an external server through `setup.downloads`). Unlike
terraform-ls, Pyright ships as a single cross-platform JS bundle, so there
is exactly one download and the launcher only needs to locate Node — no
per-platform binaries.

## Server

- **Pyright 1.1.410** (latest as of 2026-06-04), the npm distribution.
- Run as: `node <pluginDir>/server/package/langserver.index.js --stdio`.
- Verified: the langserver starts under Node and answers an LSP
  `initialize` with full capabilities (completion, definition, hover,
  document symbols, call hierarchy, code actions, …).

## Requirements

- **Node.js on PATH** (Pyright is a Node program — analogous to the Java
  plugin requiring a JDK). README states Node 18+.
- **Python interpreter: optional but recommended.** Pyright bundles
  typeshed for the standard library, but resolves third-party imports from
  the active environment; it auto-detects `python` / virtualenvs. Without
  one, third-party imports may show as unresolved.

## Files

```
python/
  plugin.json
  grammar.json
  language-configuration.json
  launch.sh
  launch.cmd
  README.md
```

Plus an update to the top-level `README.md` plugin table.

### plugin.json

- `id`: `hive-ide-official-plugins/python`
- `name`: `Python`
- `version`: `0.1.0`
- `description`: notes Pyright + Node-on-PATH requirement.
- `engines.hive`: `^0.1.0`
- `contributes.languages[0]`:
  - `id`: `python`
  - `extensions`: `[".py", ".pyi"]`
  - `aliases`: `["Python"]`
  - `configuration`: `./language-configuration.json`
  - `grammar`: `./grammar.json`
- `contributes.languageServers[0]`:
  - `language`: `python`
  - `command`: `${pluginDir}/launch.sh`
  - `args`: `[]`
  - `transport`: `stdio`
  - `cwd`: `${pluginDir}`
- `setup.downloads`: one entry (below).

### setup.downloads

Single cross-platform entry (npm tarballs are immutable per version, so
`sha256` is safe and included):

| field | value |
|---|---|
| `url` | `https://registry.npmjs.org/pyright/-/pyright-1.1.410.tgz` |
| `extractTo` | `./server` |
| `sha256` | `4d6b7a25f9617ea8ff7b2e98cd87c146d132a95cbfb29bf58bd638018a76ac48` |
| `archive` | `tar.gz` |

The tarball extracts to `./server/package/`. Entry point:
`./server/package/langserver.index.js`.

### launch.sh (POSIX)

1. `set -euo pipefail`; `HERE` = script dir.
2. Locate Node: prefer `command -v node`; error to stderr and exit 1 if
   not found, instructing the user to install Node 18+.
3. `SERVER="${HERE}/server/package/langserver.index.js"`; error if missing
   (setup download may have failed — toggle plugin off/on).
4. `exec "$NODE_BIN" "$SERVER" --stdio`.

### launch.cmd (Windows)

- Locate `node` via `where node`; error to stderr if missing.
- Error if `%HERE%\server\package\langserver.index.js` missing.
- Run `node "%HERE%\server\package\langserver.index.js" --stdio`.

### grammar.json (Monarch / Python)

- `keywords`: `def`, `class`, `if`, `elif`, `else`, `for`, `while`,
  `return`, `import`, `from`, `as`, `with`, `try`, `except`, `finally`,
  `raise`, `lambda`, `yield`, `global`, `nonlocal`, `pass`, `break`,
  `continue`, `and`, `or`, `not`, `in`, `is`, `async`, `await`, `del`,
  `assert`, `match`, `case`.
- `literals`: `True`, `False`, `None`.
- `builtins` (subset highlighted as type/function): `print`, `len`,
  `range`, `int`, `str`, `float`, `bool`, `list`, `dict`, `set`, `tuple`,
  `self`, `super`, `isinstance`, `Exception`.
- Comments: `#` line.
- Strings: single `'`, double `"`, triple `'''`/`"""`, with optional
  `f`/`r`/`b`/`rb` prefixes; f-strings highlighted as strings (no nested
  interpolation tokenizing in v1 — YAGNI).
- Decorators: `@name`.
- Numbers (int, float, hex, binary), operators, delimiters.

### language-configuration.json

- `comments`: `lineComment` `#` (no block comment).
- `brackets`: `{}`, `[]`, `()`.
- `autoClosingPairs`: brackets, `"`, `'`, and triple-quote pairs.
- `surroundingPairs`: brackets, `"`, `'`.

### README.md

Title; requirements (Node 18+ on PATH; Python interpreter optional);
install (From GitHub, tag `python-vX.Y.Z`); first-enable download note
(~10MB, one cross-platform bundle); features (LSP standard set from
Pyright); troubleshooting (Node missing, third-party imports unresolved →
select interpreter); reporting bugs.

## Release

Tag `python-v0.1.0` triggers `.github/workflows/release.yml`, which
tarballs the `python/` folder.

## Out of scope

- Bundling Node or a Python interpreter.
- Debugging (DAP), refactoring beyond what Pyright provides.
- f-string interpolation tokenizing in the grammar.
- `.ipynb` notebooks.
