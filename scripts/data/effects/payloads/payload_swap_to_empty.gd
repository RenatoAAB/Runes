class_name PayloadSwapToEmpty
extends EffectPayload

## Swaps the source rune to an empty target slot.
## Used for: Poeira (swap to random empty on panel).

@export var random_target: bool = true  ## If true, picks random empty from targets

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Find empty slots in targets
	var empty_slots: Array[GridSlot] = []
	for slot in targets:
		if slot.is_empty():
			empty_slots.append(slot)
	
	if empty_slots.is_empty():
		print("%s: No empty slot found for swap" % source_rune.data.rune_name)
		return
	
	# Pick target slot
	var target_slot: GridSlot
	if random_target and empty_slots.size() > 1:
		target_slot = empty_slots[randi() % empty_slots.size()]
	else:
		target_slot = empty_slots[0]
	
	# Get source slot
	var source_slot = context.current_slot
	if not source_slot:
		print("%s: No source slot in context" % source_rune.data.rune_name)
		return
	
	# Perform swap
	source_slot.remove_rune()
	target_slot.set_rune(source_rune)
	
	context.grid.slot_changed.emit(source_slot.grid_position)
	context.grid.slot_changed.emit(target_slot.grid_position)
	
	print("%s: Swapped from %s to %s" % [source_rune.data.rune_name, str(source_slot.grid_position), str(target_slot.grid_position)])


func get_description() -> String:
	if random_target:
		return "Swaps to random empty slot"
	return "Swaps to first empty slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
