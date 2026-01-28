class_name SlotPayloadStabilizerBegin
extends SlotEffectPayload

## Enables stabilizer scoring override for the current activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot:
		return
	context.set_meta("stabilizer_active", true)
	context.set_meta("stabilizer_used", false)

func get_description() -> String:
	return "Sets score to 100 for this activation"
