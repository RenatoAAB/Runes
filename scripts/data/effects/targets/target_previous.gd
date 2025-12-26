class_name TargetPrevious
extends EffectTarget

## Targets the previously activated rune in the reader sequence.

@export var steps_back: int = 1

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var current_index = context.current_step_index
	var target_index = current_index - steps_back
	
	if target_index >= 0 and target_index < context.grid.grid.size():
		var target_slot = context.grid.grid[target_index]
		if not target_slot.is_empty():
			return [target_slot]
	return []

func get_description() -> String:
	if steps_back == 1:
		return "Previous Rune"
	else:
		return "%d Runes back" % steps_back

func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
