class_name SlotPayloadPurifierNext
extends SlotEffectPayload

## If this read consumed a mana anomaly on this slot, apply x3 score.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	if not context.grid or not context.grid.slot_processor:
		return
	var had_anomaly = context.grid.slot_processor.get_slot_data(slot, "purifier_had_anomaly", false)
	context.grid.slot_processor.clear_slot_data(slot, "purifier_had_anomaly")
	if not had_anomaly:
		return
	var current_mult = slot.rune.stat_modifiers.get("score_multiplier", 1.0)
	slot.rune.stat_modifiers["score_multiplier"] = current_mult * 3.0
	context.grid.slot_processor.set_slot_data(slot, "purifier_mult", current_mult)

func get_description() -> String:
	return "If read with mana anomaly, consume it and score x3"
