class_name ConditionElementAdjacentNew
extends NewEffectCondition

## True if any adjacent slot has a rune with required element(s).

@export var required_elements: Array[GameEnums.Element] = []
@export var include_diagonals: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	for slot in neighbors:
		if slot.is_empty():
			continue
		for elem in slot.rune.get_elements():
			if elem in required_elements:
				EffectLogger.log_condition(ctx, self, true)
				return true

	EffectLogger.log_condition(ctx, self, false)
	return false


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var result: Array[GridSlot] = []
	for slot in neighbors:
		if slot.is_empty():
			continue
		for elem in slot.rune.get_elements():
			if elem in required_elements:
				result.append(slot)
				break
	return result


func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	var elems_str = ElementIcons.join(required_elements)
	return "adjacent%s to %s" % [diag_str, elems_str]


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC]
