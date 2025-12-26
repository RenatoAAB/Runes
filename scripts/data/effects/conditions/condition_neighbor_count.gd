class_name ConditionNeighborCount
extends EffectCondition

@export var required_count: int = 1
@export var check_diagonals: bool = false

enum Comparison {
	GREATER_THAN_OR_EQUAL, # >=
	LESS_THAN_OR_EQUAL,    # <=
	EQUAL                  # ==
}

@export var comparison: Comparison = Comparison.GREATER_THAN_OR_EQUAL

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
			
	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			return count >= required_count
		Comparison.LESS_THAN_OR_EQUAL:
			return count <= required_count
		Comparison.EQUAL:
			return count == required_count
	return false

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
	
	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			return "at least %d %s" % [required_count, type]
		Comparison.LESS_THAN_OR_EQUAL:
			return "at most %d %s" % [required_count, type]
		Comparison.EQUAL:
			return "exactly %d %s" % [required_count, type]
	return ""

func get_keywords() -> Array[StringName]:
	if filter_by_element:
		return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
	return [Keywords.ADJACENT]
