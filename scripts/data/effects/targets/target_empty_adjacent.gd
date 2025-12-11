class_name TargetEmptyAdjacent
extends EffectTarget

## Returns only empty adjacent slots.

@export var include_diagonals: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var empty: Array[GridSlot] = []
	for slot in neighbors:
		if slot.is_empty():
			empty.append(slot)
	return empty

func get_description() -> String:
	var desc = "Empty Adjacent"
	if include_diagonals:
		desc += " (incl. diag)"
	return desc
