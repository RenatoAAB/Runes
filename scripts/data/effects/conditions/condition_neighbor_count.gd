class_name ConditionNeighborCount
extends EffectCondition

const ElementIcons = preload("res://scripts/core/element_icons.gd")

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
@export var required_element: GameEnums.Element = GameEnums.Element.FIRE

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, check_diagonals)
	var count = 0
	for neighbor in neighbors:
		if not neighbor.is_empty():
			if filter_by_element:
				if required_element in neighbor.rune.get_elements():
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
		if not n.is_empty() and required_element in n.rune.get_elements():
			filtered.append(n)
	return filtered

func get_description() -> String:
	var type = "neighbors"
	if filter_by_element:
		type = "%s neighbors" % ElementIcons.get_bbcode(required_element)
	
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
