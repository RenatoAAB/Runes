class_name TargetAdjacent
extends EffectTarget

@export var include_diagonals: bool = false

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
