class_name SelectorFormation
extends EffectSelector

## Selects all occupied slots in the same Formação Rochosa as the source rune.
## Returns empty array if source is not part of a formation (< 2 connected earth).
## Used by Praia (+1 activation to formation) and Sedimentação (trigger all in formation).

@export var include_self: bool = true


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	if formation.is_empty():
		return []

	var result: Array[GridSlot] = []
	for slot in formation:
		if not include_self and slot == ctx.source_slot:
			continue
		if not slot.is_empty():
			result.append(slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	return "Formação Rochosa"


func get_keywords() -> Array[StringName]:
	return []
