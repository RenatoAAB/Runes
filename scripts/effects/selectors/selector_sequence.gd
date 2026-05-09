class_name SelectorSequence
extends EffectSelector

## Selects previous/next slots in the reader traversal order.

enum Direction {
	PREVIOUS,
	NEXT,
	BOTH
}

@export var direction: Direction = Direction.NEXT
@export var include_self: bool = false
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []

	var traversal := _get_readable_traversal(ctx)
	if traversal.is_empty():
		return []

	var current_idx := -1
	var step_idx := ctx.battle.current_step_index
	if step_idx >= 0 and step_idx < traversal.size() and traversal[step_idx] == ctx.source_slot.grid_position:
		current_idx = step_idx
	else:
		current_idx = traversal.find(ctx.source_slot.grid_position)

	if current_idx < 0:
		return []

	var result: Array[GridSlot] = []

	var indices: Array[int] = []
	if direction == Direction.PREVIOUS or direction == Direction.BOTH:
		indices.append(current_idx - 1)
	if direction == Direction.NEXT or direction == Direction.BOTH:
		indices.append(current_idx + 1)

	for idx in indices:
		if idx < 0 or idx >= traversal.size():
			continue
		var slot = ctx.battle.grid.get_slot(traversal[idx])
		if not slot or slot.is_void():
			continue
		if filter and not filter.matches(slot, ctx.battle):
			continue
		result.append(slot)

	if include_self and not ctx.source_slot.is_void():
		if not filter or filter.matches(ctx.source_slot, ctx.battle):
			result.append(ctx.source_slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func _get_readable_traversal(ctx: EffectContext) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return coords

	var path_length := ctx.battle.get_reader_path_length()
	if path_length > 0:
		for i in range(path_length):
			var coord = ctx.battle.get_reader_coord(i)
			if coord.x >= 0:
				coords.append(coord)
		return coords

	# Fallback for contexts outside an active reader run.
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var coord = Vector2i(x, y)
			var slot = ctx.battle.grid.get_slot(coord)
			if slot and not slot.is_void():
				coords.append(coord)
	return coords


func get_description() -> String:
	match direction:
		Direction.PREVIOUS:
			return "Previous Slot"
		Direction.NEXT:
			return "Next Slot"
		Direction.BOTH:
			return "Prev & Next Slots"
	return ""


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
