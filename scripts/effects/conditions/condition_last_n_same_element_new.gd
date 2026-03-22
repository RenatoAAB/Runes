class_name ConditionLastNSameElementNew
extends NewEffectCondition

## True when the last N activations share at least one common element.

@export var activation_count: int = 3


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle:
		return false
	var result = ctx.battle.last_n_same_element(activation_count)
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle:
		return []
	var result: Array[GridSlot] = []
	var history = ctx.battle.get_last_n_activations(activation_count)
	for entry in history:
		var pos: Vector2i = entry.get("slot_position", Vector2i(-1, -1))
		if pos.x >= 0 and ctx.battle.grid:
			var slot = ctx.battle.grid.get_slot(pos)
			if slot:
				result.append(slot)
	return result


func get_description() -> String:
	return "last %d activations were the same element" % activation_count


func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
