class_name ValuePer
extends Resource

## Defines a dynamic counting axis for ValueResolver.
## Each ValuePer adds (count * per_value) to the resolved amount.
## Example: "+5 per adjacent earth" → CountSource.ADJACENT + filter(earth) + per_value=5

enum CountSource {
	ADJACENT,               ## Count adjacent slots matching filter
	ADJACENT_DIAGONAL,      ## Count adjacent + diagonal slots matching filter
	PANEL,                  ## Count all slots in panel matching filter
	TARGETS,                ## Count selected targets matching filter
	SELF_REMAINING,         ## Source rune's remaining activations
	TARGETS_REMAINING,      ## Count of target runes with remaining activations
	TARGETS_REMAINING_SUM,  ## Sum of remaining activations across targets
	ROUND_ACTIVATIONS,      ## Total activations this round
	ROUND_DESTROYED,        ## Runes destroyed this round
	ROUND_CREATED,          ## Runes created this round
	UNIQUE_RUNES,           ## Unique runes activated this round
	ELEMENT_CYCLES,         ## Complete element cycles this round
	DISTINCT_ELEMENTS_ADJ,  ## Count of distinct elements in adjacent slots
	RUNES_NOT_MOVED,        ## Runes that were NOT moved during planning
}

enum AggregateMode {
	SUM,    ## Add count * per_value
	COUNT,  ## Just count matches (per_value acts as multiplier)
}

@export var source: CountSource = CountSource.ADJACENT
@export var per_value: float = 1.0
@export var filter: SlotFilter
@export var aggregate: AggregateMode = AggregateMode.SUM


func count(ctx: EffectContext, targets: Array[GridSlot] = []) -> int:
	if not ctx:
		return 0

	match source:
		CountSource.ADJACENT:
			return _count_neighbors(ctx, false)
		CountSource.ADJACENT_DIAGONAL:
			return _count_neighbors(ctx, true)
		CountSource.PANEL:
			return _count_panel(ctx)
		CountSource.TARGETS:
			return _count_targets(targets, ctx)
		CountSource.SELF_REMAINING:
			return _get_self_remaining(ctx)
		CountSource.TARGETS_REMAINING:
			return _count_targets_with_remaining(targets, ctx)
		CountSource.TARGETS_REMAINING_SUM:
			return _sum_targets_remaining(targets, ctx)
		CountSource.ROUND_ACTIVATIONS:
			return ctx.battle.get_total_activations_this_round() if ctx.battle else 0
		CountSource.ROUND_DESTROYED:
			return ctx.battle.runes_destroyed_this_round if ctx.battle else 0
		CountSource.ROUND_CREATED:
			return ctx.battle.runes_created_this_round if ctx.battle else 0
		CountSource.UNIQUE_RUNES:
			return ctx.battle.get_unique_runes_count() if ctx.battle else 0
		CountSource.ELEMENT_CYCLES:
			return ctx.battle.element_cycles_completed if ctx.battle else 0
		CountSource.DISTINCT_ELEMENTS_ADJ:
			return _count_distinct_elements_adjacent(ctx)
		CountSource.RUNES_NOT_MOVED:
			return ctx.battle.runes_not_moved_count if ctx.battle else 0
	return 0


func get_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return []

	match source:
		CountSource.ADJACENT:
			return _get_matching_neighbors(ctx, false)
		CountSource.ADJACENT_DIAGONAL:
			return _get_matching_neighbors(ctx, true)
		CountSource.PANEL:
			return _get_matching_panel(ctx)
		_:
			return []


func get_description() -> String:
	var source_desc = _get_source_description()
	var filter_desc = filter.get_description() if filter else ""
	if filter_desc != "":
		return "%s %s" % [source_desc, filter_desc]
	return source_desc


func _get_source_description() -> String:
	match source:
		CountSource.ADJACENT, CountSource.ADJACENT_DIAGONAL:
			return "adjacent rune"
		CountSource.PANEL:
			return "rune in panel"
		CountSource.TARGETS:
			return "target"
		CountSource.SELF_REMAINING:
			return "own remaining activation"
		CountSource.TARGETS_REMAINING:
			return "target with remaining activations"
		CountSource.TARGETS_REMAINING_SUM:
			return "remaining activation in targets"
		CountSource.ROUND_ACTIVATIONS:
			return "activation this round"
		CountSource.ROUND_DESTROYED:
			return "rune destroyed this round"
		CountSource.ROUND_CREATED:
			return "rune created this round"
		CountSource.UNIQUE_RUNES:
			return "unique rune activated"
		CountSource.ELEMENT_CYCLES:
			return "element cycle completed"
		CountSource.DISTINCT_ELEMENTS_ADJ:
			return "distinct element adjacent"
		CountSource.RUNES_NOT_MOVED:
			return "rune not moved"
	return "unknown"


func _count_neighbors(ctx: EffectContext, include_diagonals: bool) -> int:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return 0
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var count_val = 0
	for slot in neighbors:
		if _matches_filter(slot, ctx):
			count_val += 1
	return count_val


func _get_matching_neighbors(ctx: EffectContext, include_diagonals: bool) -> Array[GridSlot]:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var result: Array[GridSlot] = []
	for slot in neighbors:
		if _matches_filter(slot, ctx):
			result.append(slot)
	return result


func _count_panel(ctx: EffectContext) -> int:
	if not ctx.battle or not ctx.battle.grid:
		return 0
	var count_val = 0
	for slot in ctx.battle.grid.grid:
		if slot.is_void():
			continue
		if _matches_filter(slot, ctx):
			count_val += 1
	return count_val


func _get_matching_panel(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx.battle or not ctx.battle.grid:
		return []
	var result: Array[GridSlot] = []
	for slot in ctx.battle.grid.grid:
		if slot.is_void():
			continue
		if _matches_filter(slot, ctx):
			result.append(slot)
	return result


func _count_targets(targets: Array[GridSlot], ctx: EffectContext) -> int:
	var count_val = 0
	for slot in targets:
		if _matches_filter(slot, ctx):
			count_val += 1
	return count_val


func _get_self_remaining(ctx: EffectContext) -> int:
	if not ctx.source_rune:
		return 0
	return max(0, ctx.source_rune.get_max_activations() - ctx.source_rune.current_activations + 1)


func _count_targets_with_remaining(targets: Array[GridSlot], ctx: EffectContext) -> int:
	var count_val = 0
	for slot in targets:
		if slot.is_empty():
			continue
		if not _matches_filter(slot, ctx):
			continue
		var remaining = slot.rune.get_max_activations() - slot.rune.current_activations
		if remaining > 0:
			count_val += 1
	return count_val


func _sum_targets_remaining(targets: Array[GridSlot], ctx: EffectContext) -> int:
	var total = 0
	for slot in targets:
		if slot.is_empty():
			continue
		if not _matches_filter(slot, ctx):
			continue
		total += slot.rune.get_max_activations() - slot.rune.current_activations
	return total


func _count_distinct_elements_adjacent(ctx: EffectContext) -> int:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return 0
	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position)
	var seen: Dictionary = {}
	for slot in neighbors:
		if slot.is_empty():
			continue
		for elem in slot.rune.get_elements():
			seen[elem] = true
	return seen.size()


func _matches_filter(slot: GridSlot, ctx: EffectContext) -> bool:
	if not filter:
		# No filter = match occupied slots by default (most common use case)
		return not slot.is_empty()
	return filter.matches(slot, ctx.battle)
