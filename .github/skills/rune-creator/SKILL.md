---
name: rune-creator
description: Procedural guide for adding or modifying rune resources (.tres) in this Godot rune project. Use when creating new runes, wiring effects (conditions/targets/payloads), updating icons, or adjusting descriptions/elements/rarity.
---

# Rune Creator

How to author a new rune using existing reusable pieces.

## Regras gerais
- Todas as runas têm 1 ativação e são indestrutíveis, salvo indicação contrária.
- Adjacência é imediata (sem diagonais), salvo indicação contrária.
- Runas de elemento puro têm apenas 1 elemento.
- Runas só têm efeitos aditivos.
- Slots multiplicam localmente; Painéis e Relíquias multiplicam globalmente.

## Quick workflow
- Pick tier/rarity/elements. Default tier 1; rarity follows element count (1=common, 2=uncommon, etc.).
- Copy a similar rune in `resources/runes/<rarity>/` and edit in-place.
- Prefer existing building blocks: `rune_effect.gd`, conditions in `resources/effects/conditions/`, targets in `resources/effects/targets/`, payloads in `resources/effects/payloads/`.
- Choose an icon from `sprites/icons/runes/` and set `textures = [ExtResource("<icon>")]` (one texture per tier unless variant art exists).
- Write a description with the given text in the prompt; 
- Prefer not to create new resources, use generic runeEffects and configure it with the already existing parts
- if needed, create new scripts for new required behavior

## Review
- Review the tooltip that will be created by the new effects. If it is confusing, adjust it.
- Verifique se o comportamento está corretamente suportado pelos componentes envolvidos

## Notes from recent runes
- Diagonal adjacency: set `include_diagonals = true` on the `TargetAdjacent` sub-resource (Óleo uses this).
- Counting remaining activations only for certain elements: set `allowed_elements = [FIRE]` in `payload_score_per_remaining_activations` and choose `activation_source = TARGETS` (counting runes) or `TARGETS_SUM` (summing charges).
- Element-linked descriptions auto-render icons when payload/condition specifies elements; keep descriptions short and factual.

## Checklist before shipping
- [ ] Correct folder by rarity and `elements` matches gameplay intent.
- [ ] Description matches implemented effects
- [ ] Textures array not empty and UID/path valid.
- [ ] Effects array references only existing sub-resources/ext_resources.
- [ ] If new parameters added to payloads, ensure tooltips render (e.g., `allowed_elements` for remaining-activations).
- [ ] Load in Godot and verify tooltip and scoring in a test grid.
