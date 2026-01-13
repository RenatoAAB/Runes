class_name ConditionDistinctElementsAdjacent
extends EffectCondition

## Returns true if there are at least N distinct base elements adjacent.
## Used for: Metal (2+ distinct), Energia (5 distinct), Djinn (4 distinct).

@export var min_distinct_elements: int = 2
@export var include_diagonals: bool = false

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var distinct_elements: Array[GameEnums.Element] = []
	
	for slot in neighbors:
		if slot.is_empty():
			continue
		
		var base_elements = GameEnums.normalize_elements(slot.rune.data.elements)
		
		for base in base_elements:
			if base not in distinct_elements:
				distinct_elements.append(base)
	
	return distinct_elements.size() >= min_distinct_elements


func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var relevant: Array[GridSlot] = []
	for slot in neighbors:
		if not slot.is_empty():
			relevant.append(slot)
	return relevant


func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	return "adjacent%s to %d+ distinct elements" % [diag_str, min_distinct_elements]


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
