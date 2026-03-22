class_name ConditionDistinctElementsAdjacentNew
extends NewEffectCondition

## True if there are at least N distinct elements adjacent.

@export var min_distinct_elements: int = 2
@export var include_diagonals: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var distinct: Array[GameEnums.Element] = []

	for slot in neighbors:
		if slot.is_empty():
			continue
		for elem in GameEnums.normalize_elements(slot.rune.get_elements()):
			if elem not in distinct:
				distinct.append(elem)

	var result = distinct.size() >= min_distinct_elements
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var result: Array[GridSlot] = []
	for slot in neighbors:
		if not slot.is_empty():
			result.append(slot)
	return result


func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	return "adjacent%s to %d+ distinct elements" % [diag_str, min_distinct_elements]


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
