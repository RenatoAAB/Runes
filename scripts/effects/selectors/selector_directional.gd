class_name SelectorDirectional
extends EffectSelector

## Selects a slot in a specific direction (above/below/left/right).

enum Direction {
	ABOVE,
	BELOW,
	LEFT,
	RIGHT
}

@export var direction: Direction = Direction.BELOW
@export var include_if_empty: bool = true
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var pos = ctx.source_slot.grid_position
	var target_pos: Vector2i

	match direction:
		Direction.ABOVE:
			if pos.y <= 0:
				return []
			target_pos = Vector2i(pos.x, pos.y - 1)
		Direction.BELOW:
			if pos.y >= GridManager.GRID_SIZE - 1:
				return []
			target_pos = Vector2i(pos.x, pos.y + 1)
		Direction.LEFT:
			if pos.x <= 0:
				return []
			target_pos = Vector2i(pos.x - 1, pos.y)
		Direction.RIGHT:
			if pos.x >= GridManager.GRID_SIZE - 1:
				return []
			target_pos = Vector2i(pos.x + 1, pos.y)

	var target_slot = ctx.battle.grid.get_slot(target_pos)
	if not target_slot:
		return []

	if target_slot.is_empty() and not include_if_empty:
		return []

	if filter and not filter.matches(target_slot, ctx.battle):
		return []

	var result: Array[GridSlot] = [target_slot]
	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	match direction:
		Direction.ABOVE:
			return "Slot above"
		Direction.BELOW:
			return "Slot below"
		Direction.LEFT:
			return "Slot to left"
		Direction.RIGHT:
			return "Slot to right"
	return "Directional slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.NEIGHBORS]
