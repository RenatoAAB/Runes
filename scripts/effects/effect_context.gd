class_name EffectContext
extends RefCounted

## Unified context object passed through the entire effect pipeline.
## Replaces the loose (source_rune, context, source_slot) parameter pattern.

var source_rune: RuneInstance
var source_slot: GridSlot
var battle: BattleContext
var effect_index: int = 0
var can_evaluate: bool = true

## One contribution per GameEffect execution, including conditions inside actions.
## A stack preserves the parent scope when copied effects reuse this context.
var _condition_recorded_stack: Array[bool] = []


func begin_effect_execution() -> void:
	_condition_recorded_stack.append(false)


func end_effect_execution() -> void:
	_condition_recorded_stack.pop_back()


func record_successful_condition() -> void:
	if not battle:
		return
	if not _condition_recorded_stack.is_empty():
		var index := _condition_recorded_stack.size() - 1
		if _condition_recorded_stack[index]:
			return
		_condition_recorded_stack[index] = true
	battle.record_successful_condition()


func _init(p_source_rune: RuneInstance = null, p_source_slot: GridSlot = null, p_battle: BattleContext = null) -> void:
	source_rune = p_source_rune
	source_slot = p_source_slot
	battle = p_battle
