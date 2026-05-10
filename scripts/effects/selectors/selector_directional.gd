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

	var target_slot = _get_first_constructed_slot_in_direction(ctx.battle.grid, ctx.source_slot.grid_position)
	if not target_slot:
		return []

	if target_slot.is_empty() and not include_if_empty:
		return []

	if filter and not filter.matches(target_slot, ctx.battle):
		return []

	var result: Array[GridSlot] = [target_slot]
	EffectLogger.log_selector(ctx, self, result)
	return result


func _get_first_constructed_slot_in_direction(grid: GridManager, source_pos: Vector2i) -> GridSlot:
	var step = _get_direction_step()
	if step == Vector2i.ZERO:
		return null

	var cursor = source_pos + step
	while grid.is_valid_coord(cursor):
		var slot = grid.get_slot(cursor)
		if slot and not slot.is_void():
			return slot
		cursor += step

	return null


func _get_direction_step() -> Vector2i:
	match direction:
		Direction.ABOVE:
			return Vector2i.UP
		Direction.BELOW:
			return Vector2i.DOWN
		Direction.LEFT:
			return Vector2i.LEFT
		Direction.RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO


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
