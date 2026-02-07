class_name SlotPayloadEnhancerApply
extends SlotEffectPayload

## Applies an extra copy of any buffs gained during activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	# Enhancer behavior is now handled at buff application time.
	return

func get_description() -> String:
	return "Doubles buffs applied to the rune in this slot"
