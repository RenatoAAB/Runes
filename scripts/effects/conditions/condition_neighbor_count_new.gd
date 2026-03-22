class_name ConditionNeighborCountNew
extends NewEffectCondition

## True when neighbor count meets a comparison threshold.

enum Comparison {
	GREATER_THAN_OR_EQUAL,
	LESS_THAN_OR_EQUAL,
	EQUAL
}

@export var required_count: int = 1
@export var check_diagonals: bool = false
@export var comparison: Comparison = Comparison.GREATER_THAN_OR_EQUAL
@export var filter: SlotFilter


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, check_diagonals)
	var count = 0
	for slot in neighbors:
		if _matches(slot, ctx):
			count += 1

	var result = false
	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			result = count >= required_count
		Comparison.LESS_THAN_OR_EQUAL:
			result = count <= required_count
		Comparison.EQUAL:
			result = count == required_count

	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, check_diagonals)
	var result: Array[GridSlot] = []
	for slot in neighbors:
		if _matches(slot, ctx):
			result.append(slot)
	return result


func _matches(slot: GridSlot, ctx: EffectContext) -> bool:
	if filter:
		return filter.matches(slot, ctx.battle)
	return not slot.is_empty()


func get_description() -> String:
	var type = "neighbors"
	if filter:
		var f_desc = filter.get_description()
		if not f_desc.is_empty():
			type = "%s neighbors" % f_desc
	if check_diagonals:
		type += " (incl. diag)"

	match comparison:
		Comparison.GREATER_THAN_OR_EQUAL:
			return "at least %d %s" % [required_count, type]
		Comparison.LESS_THAN_OR_EQUAL:
			return "at most %d %s" % [required_count, type]
		Comparison.EQUAL:
			return "exactly %d %s" % [required_count, type]
	return ""


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT]
