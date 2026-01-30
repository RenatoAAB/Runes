class_name SlotPayloadStabilizerBegin
extends SlotEffectPayload

## Enables stabilizer scoring override for the current activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot:
		return
	if not context.grid or not context.grid.slot_processor:
		return
	context.grid.slot_processor.set_slot_data(slot, "stabilizer_active", true)
	context.grid.slot_processor.set_slot_data(slot, "stabilizer_used", false)

func get_description() -> String:
	return "Sets score to 100 for this activation"
