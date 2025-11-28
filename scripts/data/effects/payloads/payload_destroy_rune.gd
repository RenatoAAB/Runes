class_name PayloadDestroyRune
extends EffectPayload

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			slot.remove_rune()
			context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	return "Destroys target runes"
