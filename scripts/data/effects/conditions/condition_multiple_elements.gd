class_name ConditionMultipleElements
extends EffectCondition

## Returns true if adjacent to runes of at least N different elements.

@export var required_count: int = 3
@export var include_diagonals: bool = true

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var elements: Array[int] = []
	
	for neighbor in neighbors:
		if not neighbor.is_empty():
			var elem = neighbor.rune.data.element
			if elem not in elements:
				elements.append(elem)
	
	return elements.size() >= required_count

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return context.grid.get_neighbors(source_slot.grid_position, include_diagonals)

func get_description() -> String:
	return "adjacent to %d+ different elements" % required_count

func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
