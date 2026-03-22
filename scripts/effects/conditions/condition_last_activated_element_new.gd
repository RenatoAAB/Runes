class_name ConditionLastActivatedElementNew
extends NewEffectCondition

## True if the last activated rune had a specific element.

@export var required_element: GameEnums.Element = GameEnums.Element.FIRE


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle:
		return false

	var last_elements = ctx.battle.get_last_activated_elements()
	if last_elements.is_empty():
		return false

	var result = required_element in last_elements
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or ctx.battle.activation_history.is_empty():
		return []
	var last_entry = ctx.battle.activation_history[-1]
	var pos: Vector2i = last_entry.get("slot_position", Vector2i(-1, -1))
	if pos.x >= 0 and ctx.battle.grid:
		var slot = ctx.battle.grid.get_slot(pos)
		if slot:
			return [slot]
	return []


func get_description() -> String:
	return "last activated rune was %s" % ElementIcons.get_bbcode(required_element)


func get_keywords() -> Array[StringName]:
	return [Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
