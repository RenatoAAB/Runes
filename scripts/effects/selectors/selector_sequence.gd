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

	var pos = ctx.source_slot.grid_position
	var current_idx = pos.y * GridManager.GRID_SIZE + pos.x
	var result: Array[GridSlot] = []

	var indices: Array[int] = []
	if direction == Direction.PREVIOUS or direction == Direction.BOTH:
		indices.append(current_idx - 1)
	if direction == Direction.NEXT or direction == Direction.BOTH:
		indices.append(current_idx + 1)

	for idx in indices:
		if idx < 0 or idx >= GridManager.GRID_SIZE * GridManager.GRID_SIZE:
			continue
		var y = idx / GridManager.GRID_SIZE
		var x = idx % GridManager.GRID_SIZE
		var slot = ctx.battle.grid.get_slot(Vector2i(x, y))
		if slot:
			if filter and not filter.matches(slot, ctx.battle):
				continue
			result.append(slot)

	if include_self:
		if not filter or filter.matches(ctx.source_slot, ctx.battle):
			result.append(ctx.source_slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


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
