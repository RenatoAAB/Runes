class_name SlotPayloadAccumulatorStore
extends SlotEffectPayload

## Stores permanent score bonus from the current rune.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not slot or slot.is_empty() or not slot.slot:
		return
	var bonus = slot.rune.permanent_buffs.get("score_bonus", 0)
	var stored = slot.slot.get_meta("accumulator_score_bonus", 0)
	if bonus > stored:
		slot.slot.set_meta("accumulator_score_bonus", bonus)

func get_description() -> String:
	return "Stores permanent score bonus"
