class_name ConditionNeighborCount
extends EffectCondition

@export var required_count: int = 1
@export var check_diagonals: bool = false
@export var exact_match: bool = false # If true, must be exactly X. If false, >= X.

@export_group("Filter")
@export var filter_by_element: bool = false
@export var required_element: GameEnums.Element = GameEnums.Element.NEUTRAL

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, check_diagonals)
	var count = 0
	for neighbor in neighbors:
		if not neighbor.is_empty():
			if filter_by_element:
				if neighbor.rune.data.element == required_element:
					count += 1
			else:
				count += 1
			
	if exact_match:
		return count == required_count
	else:
		return count >= required_count

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, check_diagonals)
	if not filter_by_element:
		return neighbors
	
	var filtered: Array[GridSlot] = []
	for n in neighbors:
		if not n.is_empty() and n.rune.data.element == required_element:
			filtered.append(n)
	return filtered

func get_description() -> String:
	var type = "neighbors"
	if filter_by_element:
		type = GameEnums.Element.keys()[required_element].capitalize() + " neighbors"
	
	if check_diagonals:
		type += " (incl. diag)"
	
	if exact_match:
		return "exactly %d %s" % [required_count, type]
	else:
		return "at least %d %s" % [required_count, type]
