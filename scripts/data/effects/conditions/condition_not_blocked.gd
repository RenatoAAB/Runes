class_name ConditionNotBlockedByElement
extends EffectCondition

## Returns false if there's a rune of the blocking element nearby.
## Used for Light/Dark interaction.

@export var blocking_element: GameEnums.Element = GameEnums.Element.DARK
@export var include_diagonals: bool = true

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	for neighbor in neighbors:
		if not neighbor.is_empty() and neighbor.rune.data.element == blocking_element:
			return false
	return true

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var blockers: Array[GridSlot] = []
	for n in neighbors:
		if not n.is_empty() and n.rune.data.element == blocking_element:
			blockers.append(n)
	return blockers

func get_description() -> String:
	var elem_name = GameEnums.Element.keys()[blocking_element].capitalize()
	return "not blocked by %s" % elem_name

func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
