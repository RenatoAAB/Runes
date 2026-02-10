class_name SlotPayloadAccumulatorApply
extends SlotEffectPayload

## Applies the stored accumulator bonus to the current rune.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not slot or slot.is_empty() or not slot.slot:
		return
	var previously_applied = slot.slot.get_meta("accumulator_applied_bonus", 0)
	if previously_applied != 0:
		var current_cleanup = slot.rune.stat_modifiers.get("score_bonus", 0)
		slot.rune.stat_modifiers["score_bonus"] = current_cleanup - previously_applied
		slot.slot.set_meta("accumulator_applied_bonus", 0)
	var stored = slot.slot.get_meta("accumulator_score_bonus", 0)
	if stored == 0:
		return
	var current = slot.rune.stat_modifiers.get("score_bonus", 0)
	slot.rune.stat_modifiers["score_bonus"] = current + stored
	slot.slot.set_meta("accumulator_applied_bonus", stored)

func get_description() -> String:
	return "Applies stored score bonus"
