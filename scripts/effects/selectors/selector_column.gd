class_name SelectorColumn
extends EffectSelector

## Selects all slots in the same column as the source slot.

@export var include_self: bool = false
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var col = ctx.battle.grid.get_column(ctx.source_slot.grid_position.x)
	var result: Array[GridSlot] = []

	for slot in col:
		if not include_self and slot == ctx.source_slot:
			continue
		if slot.is_void():
			continue
		if filter and not filter.matches(slot, ctx.battle):
			continue
		result.append(slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	var desc = "Column"
	if include_self:
		desc += " (incl. self)"
	if filter:
		var f_desc = filter.get_description()
		if not f_desc.is_empty():
			desc += " " + f_desc
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.COLUMN]
