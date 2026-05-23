class_name SlotPayloadResonatorApply
extends SlotEffectPayload

## If this rune is activated in a simultaneous batch, multiply score by 3.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	if not context.is_simultaneous_active():
		return
	var current_mult = slot.rune.stat_modifiers.get("score_multiplier", 1.0)
	slot.rune.stat_modifiers["score_multiplier"] = current_mult * 3.0
	if context.grid and context.grid.slot_processor:
		context.grid.slot_processor.set_slot_data(slot, "resonator_mult", current_mult)

func get_description() -> String:
	return "If activated simultaneously with another rune, score x3"
