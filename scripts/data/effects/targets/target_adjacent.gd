class_name TargetAdjacent
extends EffectTarget

@export var include_diagonals: bool = false

func get_targets(source_rune: RuneInstance, grid_manager: GridManager, source_slot: GridSlot) -> Array[GridSlot]:
	return grid_manager.get_neighbors(source_slot.grid_position, include_diagonals)
