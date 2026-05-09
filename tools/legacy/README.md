# Legacy Tools Index

This folder stores historical scripts that are not part of the default active workflow.

## Status Map

| Script | Status | Notes |
|---|---|---|
| migrate_rune_effects.ps1 | legacy-complete | Phase 8.7 migration utility already applied to rune resources. |
| fix_rune_uids.ps1 | legacy-complete | Phase 8.7b UID cleanup utility for migrated rune references. |
| generate_game_effects.ps1 | legacy-complete | Historical generator for GameEffect resources from Phase 8 migration cycle. |
| migrate_phase10.ps1 | legacy-pending-verification | Archived but potentially reusable only after explicit validation and approval. |

## Operational Rule

Do not run scripts in this folder as part of normal development.

If a legacy script must be reused, execute it only in an isolated branch and validate all generated resources before merge.

## Active Tooling

Active generation utility remains in tools/generate_set3_runes.ps1.
