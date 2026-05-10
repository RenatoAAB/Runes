class_name SelectorAdjacent
extends EffectSelector

## Selects adjacent slots (orthogonal by default, optionally diagonal).

@export var include_diagonals: bool = false
@export var include_self: bool = false
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var result: Array[GridSlot] = []

	for slot in neighbors:
		if slot.is_void():
			continue
		if filter and not filter.matches(slot, ctx.battle):
			continue
		result.append(slot)

	if include_self:
		if not filter or filter.matches(ctx.source_slot, ctx.battle):
			result.append(ctx.source_slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	var desc = "Adjacent"
	if include_diagonals:
		desc += " (incl. diag)"
	if include_self:
		desc += " + Self"
	if filter:
		var f_desc = filter.get_description()
		if not f_desc.is_empty():
			desc += " " + f_desc
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.NEIGHBORS]
