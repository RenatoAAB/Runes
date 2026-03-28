class_name SelectorReaderRelative
extends EffectSelector

## Selects slots relative to the current reader position in traversal order.
## Used for "previous rune", "next rune", "N slots before/after" in reader sequence.

enum RelativeMode {
	PREVIOUS,       ## The slot read just before this one
	NEXT,           ## The slot to be read after this one
	OFFSET,         ## Specific offset from current position (negative = before, positive = after)
}

@export var mode: RelativeMode = RelativeMode.PREVIOUS
@export var offset: int = 1  ## For OFFSET mode: steps from current. For PREVIOUS/NEXT: how many steps
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return []

	var path_length = ctx.battle.get_reader_path_length()
	if path_length <= 0:
		return []

	var current_idx = ctx.battle.current_step_index
	var target_idx: int = -1

	match mode:
		RelativeMode.PREVIOUS:
			target_idx = current_idx - offset
		RelativeMode.NEXT:
			target_idx = current_idx + offset
		RelativeMode.OFFSET:
			target_idx = current_idx + offset

	if target_idx < 0 or target_idx >= path_length:
		return []

	var coord = ctx.battle.get_reader_coord(target_idx)
	if coord.x < 0:
		return []

	var slot = ctx.battle.grid.get_slot(coord)
	if not slot or slot.is_void():
		return []

	if filter and not filter.matches(slot, ctx.battle):
		return []

	var result: Array[GridSlot] = [slot]
	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	match mode:
		RelativeMode.PREVIOUS:
			if offset == 1:
				return "Previous rune"
			return "%d runes before" % offset
		RelativeMode.NEXT:
			if offset == 1:
				return "Next rune"
			return "%d runes after" % offset
		RelativeMode.OFFSET:
			if offset > 0:
				return "%d slots ahead" % offset
			elif offset < 0:
				return "%d slots behind" % abs(offset)
			return "Same slot"
	return "Reader-relative slot"


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
