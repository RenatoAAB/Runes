class_name ConditionAdjacentResidue
extends NewEffectCondition

## Checks if the source slot has adjacent slots with a specific residue type.

@export var residue_id: String = "mana_residue"
@export var min_count: int = 1
@export var include_diagonals: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var count = 0
	for slot in neighbors:
		if slot.slot and slot.slot.has_specific_residue(residue_id):
			count += 1

	return count >= min_count


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var result: Array[GridSlot] = []
	for slot in neighbors:
		if slot.slot and slot.slot.has_specific_residue(residue_id):
			result.append(slot)
	return result


func get_description() -> String:
	if min_count == 1:
		return "adjacent to %s" % residue_id
	return "adjacent to %d+ %s" % [min_count, residue_id]


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT]
