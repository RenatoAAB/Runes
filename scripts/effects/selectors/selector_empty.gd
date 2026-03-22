class_name SelectorEmpty
extends EffectSelector

## Selects empty slots using various selection modes.

enum SelectionMode {
	ALL,
	FIRST,
	RANDOM,
	CORNERS,
	EDGES,
	ADJACENT
}

@export var selection_mode: SelectionMode = SelectionMode.ALL
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return []

	var result: Array[GridSlot] = []
	var grid_size = GridManager.GRID_SIZE

	match selection_mode:
		SelectionMode.ALL:
			for slot in ctx.battle.grid.grid:
				if slot.is_void() or not slot.is_empty():
					continue
				if filter and not filter.matches(slot, ctx.battle):
					continue
				result.append(slot)

		SelectionMode.FIRST:
			for slot in ctx.battle.grid.grid:
				if slot.is_void() or not slot.is_empty():
					continue
				if filter and not filter.matches(slot, ctx.battle):
					continue
				result = [slot]
				break

		SelectionMode.RANDOM:
			var candidates: Array[GridSlot] = []
			for slot in ctx.battle.grid.grid:
				if slot.is_void() or not slot.is_empty():
					continue
				if filter and not filter.matches(slot, ctx.battle):
					continue
				candidates.append(slot)
			if not candidates.is_empty():
				result = [candidates[randi() % candidates.size()]]

		SelectionMode.CORNERS:
			var corners = [
				Vector2i(0, 0),
				Vector2i(grid_size - 1, 0),
				Vector2i(0, grid_size - 1),
				Vector2i(grid_size - 1, grid_size - 1)
			]
			for pos in corners:
				var slot = ctx.battle.grid.get_slot(pos)
				if slot and not slot.is_void() and slot.is_empty():
					if not filter or filter.matches(slot, ctx.battle):
						result.append(slot)

		SelectionMode.EDGES:
			for slot in ctx.battle.grid.grid:
				var pos = slot.grid_position
				if pos.x == 0 or pos.x == grid_size - 1 or pos.y == 0 or pos.y == grid_size - 1:
					if not slot.is_void() and slot.is_empty():
						if not filter or filter.matches(slot, ctx.battle):
							result.append(slot)

		SelectionMode.ADJACENT:
			if ctx.source_slot:
				var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, false)
				for slot in neighbors:
					if slot.is_void() or not slot.is_empty():
						continue
					if filter and not filter.matches(slot, ctx.battle):
						continue
					result.append(slot)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_preview(ctx: EffectContext) -> Array[GridSlot]:
	if selection_mode == SelectionMode.RANDOM:
		# Show all candidates for preview
		if not ctx or not ctx.battle or not ctx.battle.grid:
			return []
		var candidates: Array[GridSlot] = []
		for slot in ctx.battle.grid.grid:
			if slot.is_void() or not slot.is_empty():
				continue
			if filter and not filter.matches(slot, ctx.battle):
				continue
			candidates.append(slot)
		return candidates
	return select(ctx)


func get_description() -> String:
	match selection_mode:
		SelectionMode.ALL:
			return "All empty slots"
		SelectionMode.FIRST:
			return "First empty slot"
		SelectionMode.RANDOM:
			return "Random empty slot"
		SelectionMode.CORNERS:
			return "Empty corner slot"
		SelectionMode.EDGES:
			return "Empty edge slot"
		SelectionMode.ADJACENT:
			return "Empty adjacent slot"
	return "Empty slots"


func get_keywords() -> Array[StringName]:
	return [Keywords.NEIGHBORS]
