class_name SlotPayloadAccumulatorApply
extends SlotEffectPayload

## Applies the stored accumulator bonus to the current rune.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not slot or slot.is_empty() or not slot.slot:
		return
	var stored = slot.slot.get_meta("accumulator_score_bonus", 0)
	if stored == 0:
		return
	var current = slot.rune.stat_modifiers.get("score_bonus", 0)
	slot.rune.stat_modifiers["score_bonus"] = current + stored

func get_description() -> String:
	return "Applies stored score bonus"
