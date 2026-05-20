class_name ConditionInFormation
extends NewEffectCondition

## True if the source rune is part of a Formação Rochosa
## (a cluster of 4+ orthogonally connected earth runes).


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false
	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	var result = not formation.is_empty()
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	return ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)


func get_description() -> String:
	return "in a Formação Rochosa"


func get_keywords() -> Array[StringName]:
	return []
