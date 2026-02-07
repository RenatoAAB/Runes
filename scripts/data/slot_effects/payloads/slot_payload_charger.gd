class_name SlotPayloadCharger
extends SlotEffectPayload

## Grants +1 activation to the rune in this slot.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	var target_rune = slot.rune
	var current = target_rune.stat_modifiers.get("activation_bonus", 0)
	target_rune.stat_modifiers["activation_bonus"] = current + 1

func get_description() -> String:
	return "Rune in this slot gains +1 activation"
