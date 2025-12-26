class_name PayloadSwapRunes
extends EffectPayload

## Swaps source rune with the first non-empty target.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Find source slot
	var source_slot: GridSlot = null
	for slot in context.grid.grid:
		if slot.rune == source_rune:
			source_slot = slot
			break
	
	if not source_slot:
		return
	
	# Find first non-empty target (excluding self)
	for slot in targets:
		if not slot.is_empty() and slot != source_slot:
			# Perform swap
			var temp_rune = slot.rune
			slot.remove_rune()
			source_slot.remove_rune()
			
			slot.set_rune(source_rune)
			source_slot.set_rune(temp_rune)
			
			context.grid.slot_changed.emit(slot.grid_position)
			context.grid.slot_changed.emit(source_slot.grid_position)
			print("Swapped %s with %s" % [source_rune.data.rune_name, temp_rune.data.rune_name])
			return

func get_description() -> String:
	return "Swaps with target rune"

func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
