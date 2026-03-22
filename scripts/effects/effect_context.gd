class_name EffectContext
extends RefCounted

## Unified context object passed through the entire effect pipeline.
## Replaces the loose (source_rune, context, source_slot) parameter pattern.

var source_rune: RuneInstance
var source_slot: GridSlot
var battle: BattleContext
var effect_index: int = 0
var can_evaluate: bool = true


func _init(p_source_rune: RuneInstance = null, p_source_slot: GridSlot = null, p_battle: BattleContext = null) -> void:
	source_rune = p_source_rune
	source_slot = p_source_slot
	battle = p_battle
