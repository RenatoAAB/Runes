class_name SlotPayloadIgniterApply
extends SlotEffectPayload

## If rune is FIRE, multiply score by 3.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	var elements = GameEnums.normalize_elements(slot.rune.get_elements())
	if GameEnums.Element.FIRE not in elements:
		return
	var current_mult = slot.rune.stat_modifiers.get("score_multiplier", 1.0)
	slot.rune.stat_modifiers["score_multiplier"] = current_mult * 3.0
	if context.grid and context.grid.slot_processor:
		context.grid.slot_processor.set_slot_data(slot, "igniter_mult", current_mult)

func get_description() -> String:
	return "If Fire rune, score x3"
