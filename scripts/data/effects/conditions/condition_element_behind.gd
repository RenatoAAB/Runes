class_name ConditionElementBehind
extends EffectCondition

## Returns true if the slot directly behind (previous in reading order) has a rune of specific element(s).

@export var required_elements: Array[GameEnums.Element] = []

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var current_idx = source_slot.grid_position.y * GridManager.GRID_SIZE + source_slot.grid_position.x
	var prev_idx = current_idx - 1
	
	if prev_idx < 0:
		return false
	
	var y = prev_idx / GridManager.GRID_SIZE
	var x = prev_idx % GridManager.GRID_SIZE
	var prev_slot = context.grid.get_slot(Vector2i(x, y))
	
	if prev_slot and not prev_slot.is_empty():
		var elem = prev_slot.rune.data.element
		return elem in required_elements
	
	return false

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var current_idx = source_slot.grid_position.y * GridManager.GRID_SIZE + source_slot.grid_position.x
	var prev_idx = current_idx - 1
	
	if prev_idx >= 0:
		var y = prev_idx / GridManager.GRID_SIZE
		var x = prev_idx % GridManager.GRID_SIZE
		var slot = context.grid.get_slot(Vector2i(x, y))
		if slot:
			return [slot]
	return []

func get_description() -> String:
	var elem_names: Array[String] = []
	for elem in required_elements:
		elem_names.append(GameEnums.Element.keys()[elem])
	return "previous slot has %s" % " or ".join(elem_names)
