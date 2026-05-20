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
	ROUND_ELEMENT_ACTIVATIONS, ## Activations of specific element(s) this round (uses filter.required_elements)
	SELF_TIMES_MOVED,       ## How many times source rune was moved this round
	PANEL_RESIDUE_COUNT,    ## Count of slots with specific residue (uses filter.required_residue_id)
	COLUMN,                 ## Count slots in same column matching filter
	ROW,                    ## Count slots in same row matching filter
	FORMATION_SIZE,         ## Count of earth runes in the source's Formação Rochosa (0 if not in formation)
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
		CountSource.ROUND_ELEMENT_ACTIVATIONS:
			return _count_element_activations(ctx)
		CountSource.SELF_TIMES_MOVED:
			return ctx.battle.get_rune_move_count(ctx.source_rune) if ctx.battle and ctx.source_rune else 0
		CountSource.PANEL_RESIDUE_COUNT:
			return _count_panel_residue(ctx)
		CountSource.COLUMN:
			return _count_column(ctx)
		CountSource.ROW:
			return _count_row(ctx)
		CountSource.FORMATION_SIZE:
			return _count_formation(ctx)
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
		CountSource.FORMATION_SIZE:
			return _get_formation_slots(ctx)
		_:
			return []


func get_description() -> String:
	var source_desc = _get_source_description(filter)
	# Some sources (ROUND_ELEMENT_ACTIVATIONS, PANEL_RESIDUE_COUNT) already
	# consume the filter inside _get_source_description — don't append it again.
	if _source_consumes_filter():
		return source_desc
	var filter_desc := ""
	if filter:
		# For sources that imply occupation, skip the "occupied" slot_state label.
		var saved_state := filter.slot_state
		if _source_implies_occupied() and filter.slot_state == filter.SlotState.OCCUPIED:
			filter.slot_state = filter.SlotState.ANY
		# When the source noun is already "slot" (EMPTY filter), skip adding "empty" again
		if filter.slot_state == filter.SlotState.EMPTY:
			filter.slot_state = filter.SlotState.ANY
		filter_desc = filter.get_description()
		filter.slot_state = saved_state
	if filter_desc != "":
		return "%s %s" % [source_desc, filter_desc]
	return source_desc


func _source_consumes_filter() -> bool:
	return source == CountSource.ROUND_ELEMENT_ACTIVATIONS or source == CountSource.PANEL_RESIDUE_COUNT


## Returns true for sources where OCCUPIED slot_state is implicit and should be omitted from the description.
func _source_implies_occupied() -> bool:
	return source in [
		CountSource.ROUND_ACTIVATIONS,
		CountSource.ROUND_ELEMENT_ACTIVATIONS,
		CountSource.ROUND_DESTROYED,
		CountSource.ROUND_CREATED,
		CountSource.UNIQUE_RUNES,
	]


func _get_source_description(f: SlotFilter = null) -> String:
	var is_empty_filter := f != null and f.slot_state == f.SlotState.EMPTY
	match source:
		CountSource.ADJACENT, CountSource.ADJACENT_DIAGONAL:
			return "adjacent empty slot" if is_empty_filter else "adjacent rune"
		CountSource.PANEL:
			return "empty slot in panel" if is_empty_filter else "rune in panel"
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
		CountSource.ROUND_ELEMENT_ACTIVATIONS:
			var elem_desc := ""
			if filter and not filter.required_elements.is_empty():
				elem_desc = ElementIcons.join(filter.required_elements)
			return "%s activation this round" % elem_desc if elem_desc else "element activation this round"
		CountSource.SELF_TIMES_MOVED:
			return "time this rune was moved"
		CountSource.PANEL_RESIDUE_COUNT:
			var rid = filter.required_residue_id if filter else ""
			if rid.is_empty():
				return "residue in panel"
			return "%s in panel" % TooltipFormatter.residue_name(rid)
		CountSource.COLUMN:
			return "empty slot in column" if is_empty_filter else "rune in column"
		CountSource.ROW:
			return "empty slot in row" if is_empty_filter else "rune in row"
		CountSource.FORMATION_SIZE:
			return "%s rune in Formação Rochosa" % ElementIcons.get_bbcode(GameEnums.Element.EARTH)
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


func _count_element_activations(ctx: EffectContext) -> int:
	if not ctx.battle:
		return 0
	if filter and not filter.required_elements.is_empty():
		return ctx.battle.get_elements_activation_count(filter.required_elements)
	# No element filter: return total activations
	return ctx.battle.get_total_activations_this_round()


func _count_panel_residue(ctx: EffectContext) -> int:
	if not ctx.battle:
		return 0
	var residue_id = filter.required_residue_id if filter else ""
	if residue_id.is_empty():
		# Count all slots with any residue
		var count_val = 0
		for slot in ctx.battle.grid.grid:
			if slot.is_void():
				continue
			if slot.slot and slot.slot.has_residue():
				count_val += 1
		return count_val
	return ctx.battle.count_panel_residue(residue_id)


func _count_column(ctx: EffectContext) -> int:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return 0
	var col = ctx.battle.grid.get_column(ctx.source_slot.grid_position.x)
	var count_val = 0
	for slot in col:
		if slot == ctx.source_slot:
			continue
		if _matches_filter(slot, ctx):
			count_val += 1
	return count_val


func _count_row(ctx: EffectContext) -> int:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return 0
	var row = ctx.battle.grid.get_row(ctx.source_slot.grid_position.y)
	var count_val = 0
	for slot in row:
		if slot == ctx.source_slot:
			continue
		if _matches_filter(slot, ctx):
			count_val += 1
	return count_val


func _count_formation(ctx: EffectContext) -> int:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return 0
	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	if filter:
		var count_val = 0
		for slot in formation:
			if filter.matches(slot, ctx.battle):
				count_val += 1
		return count_val
	return formation.size()


func _get_formation_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return []
	var formation = ctx.battle.grid.get_earth_formation(ctx.source_slot.grid_position)
	if not filter:
		return formation
	var result: Array[GridSlot] = []
	for slot in formation:
		if filter.matches(slot, ctx.battle):
			result.append(slot)
	return result
