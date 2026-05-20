class_name ConditionFormationMinSize
extends NewEffectCondition

## True if the source rune's Formação Rochosa has at least [min_size] earth runes.
## Used by Rubi: requires formation >= 6.

@export var min_size: int = 6


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false
	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	var result = formation.size() >= min_size
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	return ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)


func get_description() -> String:
	return "in a formation with %d+ earth runes" % min_size


func get_keywords() -> Array[StringName]:
	return []
