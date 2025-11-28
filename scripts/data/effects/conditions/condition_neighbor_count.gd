class_name ConditionNeighborCount
extends EffectCondition

@export var required_count: int = 1
@export var check_diagonals: bool = false
@export var exact_match: bool = false # If true, must be exactly X. If false, >= X.

func evaluate(source_rune: RuneInstance, grid_manager: GridManager, source_slot: GridSlot) -> bool:
	var neighbors = grid_manager.get_neighbors(source_slot.grid_position, check_diagonals)
	var count = 0
	for neighbor in neighbors:
		if not neighbor.is_empty():
			count += 1
			
	if exact_match:
		return count == required_count
	else:
		return count >= required_count
