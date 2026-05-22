class_name ConditionFormationBorder
extends NewEffectCondition

## True if the source rune is at the border (or corner) of a Formação Rochosa.
## Border definition: part of a formation (2+ connected earth) but NOT at center
## (has fewer than 4 adjacent earth runes).


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false
	# Must be in a formation
	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	if formation.is_empty():
		EffectLogger.log_condition(ctx, self, false)
		return false
	# Must NOT be center (center = 4 adjacent earth)
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, false)
	var earth_count := 0
	for slot in neighbors:
		if not slot.is_empty() and GameEnums.has_element(slot.rune.get_elements(), GameEnums.Element.EARTH):
			earth_count += 1
	var result = earth_count < 4
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	return ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)


func get_description() -> String:
	return "at border of a Formação Rochosa"


func get_keywords() -> Array[StringName]:
	return []
