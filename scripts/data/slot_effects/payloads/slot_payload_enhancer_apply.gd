class_name SlotPayloadEnhancerApply
extends SlotEffectPayload

## Applies an extra copy of any buffs gained during activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	if not context.grid or not context.grid.slot_processor:
		return
	var snapshot: Dictionary = context.grid.slot_processor.get_slot_data(slot, "enhancer_snapshot", {})
	context.grid.slot_processor.clear_slot_data(slot, "enhancer_snapshot")
	if snapshot.is_empty():
		return
	_apply_delta(snapshot.get("permanent_buffs", {}), slot.rune.permanent_buffs)
	_apply_delta(snapshot.get("stat_modifiers", {}), slot.rune.stat_modifiers)
	_apply_delta(snapshot.get("temporary_buffs", {}), slot.rune.temporary_buffs)

func _apply_delta(before: Dictionary, after: Dictionary) -> void:
	for key in after.keys():
		var before_value = before.get(key, 0)
		var after_value = after.get(key, 0)
		var delta = after_value - before_value
		if delta != 0:
			after[key] = after_value + delta

func get_description() -> String:
	return "Doubles buffs gained while activating in this slot"
