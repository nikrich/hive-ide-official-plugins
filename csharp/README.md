# C# plugin for Hive IDE

C# language support via
[OmniSharp-roslyn](https://github.com/OmniSharp/omnisharp-roslyn), the
Roslyn-based language server that powers the official C# tooling.

## Requirements

- **.NET 6+ runtime** on your PATH (`dotnet`). The bundled OmniSharp builds
  are framework-dependent (net6.0), not self-contained, so they need a .NET
  runtime present. Check with `dotnet --version`. Install from
  <https://dotnet.microsoft.com/download> if missing.
- **A project or solution is recommended.** OmniSharp gives the best results
  when it can load a `.csproj`/`.sln`. Open your project at its root; loose
  `.cs`/`.csx` files work but with reduced cross-file analysis.

## Install

Install via Hive IDE's Plugins view:

- **From GitHub**: owner `nikrich`, repo `hive-ide-official-plugins`,
  tag `csharp-vX.Y.Z` (use the latest csharp-prefixed tag).

On first enable, the IDE downloads the OmniSharp server for your platform
(~48MB per platform; ~240MB across all five platforms upstream). This is a
one-time download. OmniSharp may take several seconds to start while it
loads your project.

## Features

Powered by OmniSharp-roslyn, you get the LSP standard set:

- Diagnostics (compiler errors and warnings)
- Completion (members, types, keywords)
- Hover (types and XML doc summaries)
- Signature help
- Goto definition / implementation
- Find references
- Document / workspace symbols
- Code actions and refactorings
- Rename

## Troubleshooting

- "Server won't start" → run `dotnet --version`. If missing, install the
  .NET 6+ runtime. If `dotnet` is present, the setup download may have
  failed — toggle the plugin off and back on.
- "No completions / unresolved types" → OmniSharp couldn't load a project.
  Open the folder containing your `.csproj`/`.sln` at the workspace root.
- "Slow on first open" → OmniSharp restores and indexes the project on
  startup; subsequent opens are faster.

## Reporting bugs

Issues: https://github.com/nikrich/hive-ide-official-plugins/issues
