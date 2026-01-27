class_name ConditionAdjacentActivationElement
extends EffectCondition

const ElementIcons = preload("res://scripts/core/element_icons.gd")

@export var required_elements: Array[GameEnums.Element] = []
@export var include_diagonals: bool = false

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	if context.activation_history.is_empty():
		return false
	var last = context.activation_history[-1]
	var activated_pos: Vector2i = last.get("slot_position", Vector2i(-1, -1))
	if not context.grid.is_valid_coord(activated_pos):
		return false
	# Ensure the activated slot is adjacent to this rune's slot.
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var is_adjacent := false
	for slot in neighbors:
		if slot.grid_position == activated_pos:
			is_adjacent = true
			break
	if not is_adjacent:
		return false
	var elements: Array[GameEnums.Element] = last.get("elements", [])
	for elem in elements:
		if elem in required_elements:
			return true
	return required_elements.is_empty()

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	if context.activation_history.is_empty():
		return []
	var last = context.activation_history[-1]
	var pos: Vector2i = last.get("slot_position", Vector2i(-1, -1))
	if not context.grid.is_valid_coord(pos):
		return []
	return [context.grid.get_slot(pos)]

func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	var elems_str = ElementIcons.join(required_elements)
	if elems_str.is_empty():
		elems_str = "rune"
	return "adjacent %s activation%s" % [elems_str, diag_str]

func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
