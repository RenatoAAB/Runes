class_name PayloadIlluminateCrystalAdjacent
extends EffectPayload

## Illuminates self and adjacent slots. If adjacent to Crystal, also illuminates Crystal's adjacents.

@export var state_id: String = "illuminated"
@export var duration: int = 5
@export var activation_bonus: int = 2

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Find source slot
	var source_slot: GridSlot = null
	for slot in context.grid.grid:
		if slot.rune == source_rune:
			source_slot = slot
			break
	
	if not source_slot:
		return
	
	var slots_to_illuminate: Array[GridSlot] = [source_slot]
	var adjacents = context.grid.get_neighbors(source_slot.grid_position, true)
	slots_to_illuminate.append_array(adjacents)
	
	# Check for Crystal adjacents and add their neighbors too
	for slot in adjacents:
		if not slot.is_empty() and slot.rune.data.element == GameEnums.Element.CRYSTAL:
			var crystal_adjacents = context.grid.get_neighbors(slot.grid_position, true)
			for crystal_adj in crystal_adjacents:
				if crystal_adj not in slots_to_illuminate:
					slots_to_illuminate.append(crystal_adj)
	
	for slot in slots_to_illuminate:
		slot.add_state(state_id, duration, 0, activation_bonus)
		context.grid.slot_changed.emit(slot.grid_position)
	
	print("Light: Illuminated %d slots" % slots_to_illuminate.size())

func get_description() -> String:
	return "Illuminates self & adjacents (Crystal spreads further)"
