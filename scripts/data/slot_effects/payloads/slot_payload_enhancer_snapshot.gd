class_name SlotPayloadEnhancerSnapshot
extends SlotEffectPayload

## Captures rune buffs before activation for Enhancer.

func execute(context: BattleContext, slot: GridSlot) -> void:
	# Enhancer behavior is now handled at buff application time.
	return

func get_description() -> String:
	return "Doubles buffs applied to the rune in this slot"
