# Hello Plugin

The canonical "smallest possible plugin" reference for Hive IDE. A
trivial plugin that demonstrates the plugin runtime (REQ-006).

> This folder is the published reference copy. The hive-ide test
> suite uses an **identical copy** in-repo at
> `examples/hello-plugin/` so the example and the runtime stay in
> lockstep.

It contributes a single language — `smiley` (.smile files) — with a tiny
Monarch grammar that highlights a handful of mood words and emoticons.

## Try it

1. In Hive IDE, open the **Plugins** view from the activity rail.
2. Click **Install → From folder…** and pick this directory
   (`examples/hello-plugin/`). The IDE copies the folder into the
   workspace plugins directory and the plugin appears in the grid.
3. Open or create a project (toggles are per-project), then enable the
   plugin via the **Enabled** checkbox on the card.
4. Create a new file with a `.smile` extension — e.g. `mood.smile` — and
   paste:

   ```
   // a tiny mood log
   joy 100
   happy :D
   sad :(
   smile
   angry :P
   ```

5. The mood words light up as keywords and the emoticons render as
   strings. Comments starting with `//` go grey.

## Files

- `plugin.json` — manifest (id, version, language contribution)
- `language-configuration.json` — Monaco `LanguageConfiguration`
  (bracket pairs, line comment marker)
- `grammar.json` — Monaco Monarch tokenizer

## Use it as a template

Copy this folder, change the `id`, `name`, language `id`, and
`extensions`. That's enough for a syntax-only plugin. For LSP support,
see [CONTRIBUTING.md](../../CONTRIBUTING.md) §4.
