class_name SlotPayloadEnhancerSnapshot
extends SlotEffectPayload

## Captures rune buffs before activation for Enhancer.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	var snapshot := {
		"permanent_buffs": slot.rune.permanent_buffs.duplicate(true),
		"stat_modifiers": slot.rune.stat_modifiers.duplicate(true),
		"temporary_buffs": slot.rune.temporary_buffs.duplicate(true)
	}
	if context.grid and context.grid.slot_processor:
		context.grid.slot_processor.set_slot_data(slot, "enhancer_snapshot", snapshot)

func get_description() -> String:
	return "Doubles buffs gained while activating in this slot"
