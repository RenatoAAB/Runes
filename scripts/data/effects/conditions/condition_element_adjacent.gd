class_name ConditionElementAdjacent
extends EffectCondition

const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Returns true if any adjacent slot has a rune of specific element(s).

@export var required_elements: Array[GameEnums.Element] = []
@export var include_diagonals: bool = false

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	
	for slot in neighbors:
		if slot.is_empty():
			continue
		
		for elem in slot.rune.data.elements:
			if elem in required_elements:
				return true
	
	return false

func get_relevant_slots(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	var neighbors = context.grid.get_neighbors(source_slot.grid_position, include_diagonals)
	var relevant: Array[GridSlot] = []
	for slot in neighbors:
		if slot.is_empty():
			continue
		
		for elem in slot.rune.data.elements:
			if elem in required_elements:
				relevant.append(slot)
				break
	return relevant

func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	var elems_str = ElementIcons.join(required_elements)
	return "adjacent%s to %s" % [diag_str, elems_str]

func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
