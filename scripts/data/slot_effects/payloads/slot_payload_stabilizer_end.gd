class_name SlotPayloadStabilizerEnd
extends SlotEffectPayload

## Clears stabilizer scoring override after activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context:
		return
	if not context.grid or not context.grid.slot_processor or not slot:
		return
	context.grid.slot_processor.clear_slot_data(slot, "stabilizer_active")
	context.grid.slot_processor.clear_slot_data(slot, "stabilizer_used")

func get_description() -> String:
	return "Clears stabilizer override"
