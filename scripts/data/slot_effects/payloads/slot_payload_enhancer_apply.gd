class_name SlotPayloadEnhancerApply
extends SlotEffectPayload

## Applies an extra copy of any buffs gained during activation.

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or not slot.rune:
		return
	var key = _get_key(slot)
	if not context.has_meta(key):
		return
	var snapshot: Dictionary = context.get_meta(key, {})
	context.set_meta(key, null)
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

func _get_key(slot: GridSlot) -> String:
	return "enhancer_snapshot_%s" % str(slot.grid_position)

func get_description() -> String:
	return "Doubles buffs gained while activating in this slot"
