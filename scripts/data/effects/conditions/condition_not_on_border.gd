class_name ConditionNotOnBorder
extends EffectCondition

## Returns true if the source slot is NOT on any edge of the grid.

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var pos = source_slot.grid_position
	var max_idx = GridManager.GRID_SIZE - 1
	
	# Check if on any border
	var is_on_border = pos.x == 0 or pos.x == max_idx or pos.y == 0 or pos.y == max_idx
	return not is_on_border

func get_description() -> String:
	return "not on border"

func get_keywords() -> Array[StringName]:
	return [Keywords.POSITION]
