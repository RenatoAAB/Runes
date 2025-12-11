class_name TargetBelow
extends EffectTarget

## Returns the slot directly below (y + 1).

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var below_pos = source_slot.grid_position + Vector2i(0, 1)
	if context.grid.is_valid_coord(below_pos):
		var slot = context.grid.get_slot(below_pos)
		if slot:
			return [slot]
	return []

func get_description() -> String:
	return "Below"
