# Runes Commands and Operations

Operational reference for agents working in this repository.

## Safety Policy / Politica de Seguranca

PT-BR:
- Execute apenas comandos necessarios para a tarefa.
- Priorize comandos read-only antes de scripts que geram ou reescrevem recursos.
- Scripts em [tools/legacy](tools/legacy) nao fazem parte do fluxo normal.

EN:
- Run only commands needed for the task.
- Prefer read-only checks before generators or rewrite scripts.
- Scripts in [tools/legacy](tools/legacy) are outside normal workflows.

## Project Root / Raiz do Projeto

- Workspace root: `C:\Users\55119\Documents\runes`
- Most commands assume PowerShell in repo root.

## Daily Read-Only Commands / Comandos de Consulta

### Fast file and text search
- `rg --files`
- `rg "EventBus|SlotReadEvent|GameEffect" scripts`
- `rg "TODO|FIXME"`

### Quick structure checks
- `Get-ChildItem tools`
- `Get-ChildItem resources/effects/rune_effects | Select-Object -First 20`
- `Get-ChildItem scripts/effects/conditions`

### Git visibility
- `git status --short`
- `git diff --name-status`
- `git diff -- docs/rune_effects_debug.md`

## Run and Debug / Execucao e Debug

Preferred in VS Code:
- Use launch profile from [.vscode/launch.json](.vscode/launch.json):
  - `GDScript: Launch Project`

Optional CLI sanity checks:
- `Get-Command godot, godot4 -ErrorAction SilentlyContinue`

## Active Generator Script / Script Gerador Ativo

Active script:
- [tools/generate_set3_runes.ps1](tools/generate_set3_runes.ps1)

Usage:
- `pwsh -ExecutionPolicy Bypass -File tools/generate_set3_runes.ps1`

When to use:
- Regenerate Set 3 resources and shared effect resources.

Caution:
- This script can modify many files under `resources/effects` and `resources/runes`.
- Use in isolated branch when possible.

## Obsidian MCP Operations / Operacoes MCP Obsidian

Check MCP configuration:
- `pwsh -ExecutionPolicy Bypass -File .github/skills/obsidian-mcp/scripts/check_mcp_status.ps1`

Config file:
- [.vscode/mcp.json](.vscode/mcp.json)

Note:
- Configuration present does not guarantee MCP tools are enabled in the chat UI.

## Legacy Scripts / Scripts Legados

Legacy scripts index:
- [tools/legacy/README.md](tools/legacy/README.md)

Archived scripts:
- [tools/legacy/migrate_rune_effects.ps1](tools/legacy/migrate_rune_effects.ps1)
- [tools/legacy/fix_rune_uids.ps1](tools/legacy/fix_rune_uids.ps1)
- [tools/legacy/generate_game_effects.ps1](tools/legacy/generate_game_effects.ps1)
- [tools/legacy/migrate_phase10.ps1](tools/legacy/migrate_phase10.ps1)

Rule:
- Do not run legacy scripts in normal development.
- `migrate_phase10.ps1` is explicitly marked legacy-pending-verification.

## Documentation Paths / Caminhos de Documentacao

Active references:
- [AGENTS.md](AGENTS.md)
- [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md)
- [docs/rune_effects_debug.md](docs/rune_effects_debug.md)

Historical references:
- [docs/historical](docs/historical)

## Suggested Pre-Change Checklist / Checklist Antes de Alterar

1. Verify current branch and working tree status.
2. Confirm whether target files are active or historical.
3. Confirm command impact radius before execution.
4. Run minimal validation after edits.
