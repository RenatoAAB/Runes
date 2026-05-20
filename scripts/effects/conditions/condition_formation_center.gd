class_name ConditionFormationCenter
extends NewEffectCondition

## True if the source rune is at the center of a Formação Rochosa.
## Center definition: has 4 orthogonally adjacent earth runes.


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, false)
	var earth_count := 0
	for slot in neighbors:
		if not slot.is_empty() and GameEnums.has_element(slot.rune.get_elements(), GameEnums.Element.EARTH):
			earth_count += 1
	var result = earth_count >= 4
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var result: Array[GridSlot] = []
	for slot in ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, false):
		if not slot.is_empty() and GameEnums.has_element(slot.rune.get_elements(), GameEnums.Element.EARTH):
			result.append(slot)
	return result


func get_description() -> String:
	return "at center of a Formação Rochosa"


func get_keywords() -> Array[StringName]:
	return []
