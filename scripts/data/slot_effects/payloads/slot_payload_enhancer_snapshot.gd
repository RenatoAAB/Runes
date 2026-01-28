class_name SlotPayloadEnhancerSnapshot
extends SlotEffectPayload

## Captures rune buffs before activation for Enhancer.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	var key = _get_key(slot)
	var snapshot := {
		"permanent_buffs": slot.rune.permanent_buffs.duplicate(true),
		"stat_modifiers": slot.rune.stat_modifiers.duplicate(true),
		"temporary_buffs": slot.rune.temporary_buffs.duplicate(true)
	}
	context.set_meta(key, snapshot)

func _get_key(slot: GridSlot) -> String:
	return "enhancer_snapshot_%s" % str(slot.grid_position)

func get_description() -> String:
	return "Doubles buffs gained while activating in this slot"
