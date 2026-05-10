class_name SelectorRelative
extends EffectSelector

## Selects a single slot at a relative offset from source.

@export var relative_position: Vector2i = Vector2i.ZERO
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var target_pos = ctx.source_slot.grid_position + relative_position
	if not ctx.battle.grid.is_valid_coord(target_pos):
		return []

	var slot = ctx.battle.grid.get_slot(target_pos)
	if not slot:
		return []
	if slot.is_void():
		return []
	if filter and not filter.matches(slot, ctx.battle):
		return []

	var result: Array[GridSlot] = [slot]
	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	return "Relative (%d, %d)" % [relative_position.x, relative_position.y]


func get_keywords() -> Array[StringName]:
	return []
