class_name PayloadDestroyRune
extends EffectPayload

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if targets.is_empty():
		return
	for slot in targets:
		if slot.is_empty():
			continue
		var rune := slot.rune
		if context:
			if context.event_bus:
				context.event_bus.notify_rune_destroyed(slot, rune)
			else:
				context.on_rune_destroyed(slot, rune)
			slot.remove_rune()
			context.grid.slot_changed.emit(slot.grid_position)

func get_description() -> String:
	return "Destroys target runes"

func get_keywords() -> Array[StringName]:
	return [Keywords.DESTROY]
