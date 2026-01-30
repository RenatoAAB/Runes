class_name SlotPayloadResonatorApply
extends SlotEffectPayload

## If all adjacent runes share an element with this rune, multiply score by 3.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not context.grid or not slot or slot.is_empty():
		return
	var current_rune = slot.rune
	var current_elements = GameEnums.normalize_elements(current_rune.get_elements())
	if current_elements.is_empty():
		return
	var neighbors = context.grid.get_neighbors(slot.grid_position)
	var has_adjacent = false
	for neighbor in neighbors:
		if neighbor.is_empty():
			return
		has_adjacent = true
		var neighbor_elements = GameEnums.normalize_elements(neighbor.rune.get_elements())
		var shares := false
		for elem in current_elements:
			if elem in neighbor_elements:
				shares = true
				break
		if not shares:
			return
	if not has_adjacent:
		return
	var current_mult = current_rune.stat_modifiers.get("score_multiplier", 1.0)
	current_rune.stat_modifiers["score_multiplier"] = current_mult * 3.0
	if context.grid and context.grid.slot_processor:
		context.grid.slot_processor.set_slot_data(slot, "resonator_mult", current_mult)

func get_description() -> String:
	return "If adjacent runes share elements, score x3"
