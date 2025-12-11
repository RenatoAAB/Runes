class_name TargetFrontEmpty
extends EffectTarget

## Returns the slot in front (next in reading order) if empty.

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var current_idx = source_slot.grid_position.y * GridManager.GRID_SIZE + source_slot.grid_position.x
	var next_idx = current_idx + 1
	
	if next_idx >= GridManager.GRID_SIZE * GridManager.GRID_SIZE:
		return []
	
	var y = next_idx / GridManager.GRID_SIZE
	var x = next_idx % GridManager.GRID_SIZE
	var next_slot = context.grid.get_slot(Vector2i(x, y))
	
	if next_slot and next_slot.is_empty():
		return [next_slot]
	return []

func get_description() -> String:
	return "Front (if empty)"
