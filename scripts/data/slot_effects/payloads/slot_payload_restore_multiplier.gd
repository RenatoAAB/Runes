class_name SlotPayloadRestoreMultiplier
extends SlotEffectPayload

## Restores score_multiplier from a stored meta key.

@export var meta_key_prefix: String = ""

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	if not context.grid or not context.grid.slot_processor:
		return
	var previous = context.grid.slot_processor.get_slot_data(slot, meta_key_prefix, null)
	context.grid.slot_processor.clear_slot_data(slot, meta_key_prefix)
	if previous == null:
		return
	slot.rune.stat_modifiers["score_multiplier"] = previous
