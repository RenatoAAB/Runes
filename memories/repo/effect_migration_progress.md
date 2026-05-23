# Effect System Migration Progress

## Phase 8 Status (as of latest session)

### Completed
- **8.1-8.3**: Shared building blocks created (34 .tres files)
  - 11 selectors in `resources/effects/shared/selectors/`
  - 7 filters in `resources/effects/shared/filters/`
  - 16 conditions in `resources/effects/shared/conditions/`
- **8.4**: Dual support code in RuneData, RuneInstance, EventBus, Reader
- **8.5**: 45 GameEffect .tres generated in `resources/effects/rune_effects/`
- **8.6**: 44 rune .tres files updated to reference new GameEffect files
- **8.7-8.9**: N/A - slot modifiers, relics, residues don't use effects array

### Not migrated (remain as RuneEffect via dual support)
- `effect_empathy_repeat_previous` - needs new ActionCopyEffects
- `effect_multiply_self_permanent` - needs new ActionMultiplySelfScore
- `effect_mundo_permanent_created` - needs ActionComposite
- `effect_sacred_spirit_bonus` - needs custom spirit count

### Key architectural decisions
- `RuneData.effects` changed from `Array[RuneEffect]` to `Array[Resource]`
- Typed arrays in .tres stripped to untyped for GameEffect compatibility
- UIDs stripped from ext_resource lines pointing to new GameEffect files
- Migration tools in `tools/` directory

### Next phases
- Phase 9: Integration verification (manual testing in Godot with EffectLogger)
- Phase 10: Cleanup legacy code (delete old payloads, targets, conditions)

## Post-migration fixes
- 2026-05-10: Added `ActionMoveRune` to support origin->target movement in GameEffect pipeline.
- 2026-05-10: Fixed Tremor to move the previous rune to the slot below (empty-only) instead of moving the source rune.
- 2026-05-10: Added movement preview links (origin/target highlight + arrow) and slot tooltip role labels for movement effects.
- 2026-05-22: Set 4 R-rune alignment pass: corrected selectors/conditions for Explosao, Supernova, Cachoeira, Redemoinho, Furacao, Erupcao, Ebulicao, Raio, Conveccao, Ordem, Entropia, Praia, Sedimentacao, Plasma, Oleo, Estagnacao.
- 2026-05-22: Added shared conditions `condition_not_first_activation` and `condition_not_first_two_activations`; generalized `ConditionNotFirstActivation` with `min_previous_activations` export.
- 2026-05-22: Extended `ActionCreateRandomRune` with `min_rarity` to support Entropia creating uncommon+ runes.
- 2026-05-23: `ActionMoveReader` now uses `reader_pending_jump_index` metadata to accumulate multiple jumps in the same step (fixes Pressurizer duplicated rewind/forward not stacking).
