class_name SlotPayloadStabilizerEnd
extends SlotEffectPayload

## Clears stabilizer scoring override after activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context:
		return
	context.set_meta("stabilizer_active", false)
	context.set_meta("stabilizer_used", false)

func get_description() -> String:
	return "Clears stabilizer override"
