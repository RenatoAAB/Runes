class_name ConditionElementNearby
extends EffectCondition

## Returns true if there's at least one rune of the specified element adjacent.

@export var required_element: GameEnums.Element = GameEnums.Element.FIRE
@export var include_diagonals: bool = true
@export var required_count: int = 1

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var count = 0
	for neighbor in neighbors:
		if not neighbor.is_empty() and neighbor.rune.data.element == required_element:
			count += 1
	return count >= required_count

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var filtered: Array[GridSlot] = []
	for n in neighbors:
		if not n.is_empty() and n.rune.data.element == required_element:
			filtered.append(n)
	return filtered

func get_description() -> String:
	var elem_name = GameEnums.Element.keys()[required_element].capitalize()
	if required_count == 1:
		return "adjacent to %s" % elem_name
	else:
		return "adjacent to %d+ %s" % [required_count, elem_name]
