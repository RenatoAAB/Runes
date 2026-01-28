class_name SlotPayloadRestoreMultiplier
extends SlotEffectPayload

## Restores score_multiplier from a stored meta key.

@export var meta_key_prefix: String = ""

func execute(context: BattleContext, slot: GridSlot) -> void:
	if not context or not slot or slot.is_empty():
		return
	var key = _get_key(slot)
	if not context.has_meta(key):
		return
	var previous = context.get_meta(key, null)
	context.set_meta(key, null)
	if previous == null:
		return
	slot.rune.stat_modifiers["score_multiplier"] = previous

func _get_key(slot: GridSlot) -> String:
	return "%s_%s" % [meta_key_prefix, str(slot.grid_position)]
