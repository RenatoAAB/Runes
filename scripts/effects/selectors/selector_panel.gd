class_name SelectorPanel
extends EffectSelector

## Selects all valid slots in the panel.

@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return []

	var result: Array[GridSlot] = []
	for slot in ctx.battle.grid.grid:
		if slot.is_void():
			continue
		if filter and not filter.matches(slot, ctx.battle):
			continue
		result.append(slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	var desc = "All panel slots"
	if filter:
		var f_desc = filter.get_description()
		if not f_desc.is_empty():
			desc = "All %s in panel" % f_desc
	return desc


func get_keywords() -> Array[StringName]:
	return []
