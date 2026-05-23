class_name SlotPayloadStabilizerEnd
extends SlotEffectPayload

## Clears Stabilizer multiplier override after activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	if not context.grid or not context.grid.slot_processor:
		return
	var previous = context.grid.slot_processor.get_slot_data(slot, "stabilizer_mult", null)
	context.grid.slot_processor.clear_slot_data(slot, "stabilizer_mult")
	if previous == null:
		return
	slot.rune.stat_modifiers["score_multiplier"] = previous

func get_description() -> String:
	return "Restores Stabilizer multiplier"
