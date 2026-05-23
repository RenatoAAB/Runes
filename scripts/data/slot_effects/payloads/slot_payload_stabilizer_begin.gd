class_name SlotPayloadStabilizerBegin
extends SlotEffectPayload

## If rune is in an earth formation, apply x2 score for this activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	if not context.grid:
		return
	var formation = context.grid.get_earth_formation(slot.grid_position)
	if formation.is_empty():
		return
	var current_mult = slot.rune.stat_modifiers.get("score_multiplier", 1.0)
	slot.rune.stat_modifiers["score_multiplier"] = current_mult * 2.0
	if context.grid.slot_processor:
		context.grid.slot_processor.set_slot_data(slot, "stabilizer_mult", current_mult)

func get_description() -> String:
	return "If in a rocky formation, score x2"
