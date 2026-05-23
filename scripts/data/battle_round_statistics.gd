class_name BattleRoundStatistics
extends RefCounted

## Immutable aggregate of all battle-round metrics.
## Built once after the Reader finishes and passed to each RelicMultiplierCalculator.
## Separates "what happened" (data) from "what to do about it" (calculators).

# --- Data already available from BattleContext ---

## Ordered list of activation entries [{elements, rune_id, slot_position, rune_instance}]
var activation_history: Array[Dictionary] = []

## Number of runes destroyed this round
var runes_destroyed_count: int = 0

## Number of runes created this round
var runes_created_count: int = 0

## Number of unique rune IDs activated
var unique_runes_count: int = 0

## Total number of activations
var total_activations: int = 0

## Activations broken down by element (GameEnums.Element → int)
var activations_by_element: Dictionary = {}

## Number of runes that were activated inside simultaneous batches
var simultaneous_runes_activated_count: int = 0

## Number of successful condition evaluations this round
var successful_conditions_count: int = 0

## Number of mana anomalies created this round
var mana_anomalies_created_count: int = 0

# --- Data computed from GridManager at end of round ---

## Number of empty slots (no rune) in the panel
var empty_slots_count: int = 0

## Number of slots whose SlotInstance has at least one active residue state
var slots_with_residue: int = 0

## Number of distinct slot types (by slot_modifier_id) in the panel
var distinct_slot_types: int = 0

## Sum of remaining activations across all runes in the panel
var remaining_activations_total: int = 0

## Number of runes with rarity Rare or higher currently in the panel
var rare_plus_runes_in_panel: int = 0

## Number of earth formations in the panel (cluster size >= 2)
var earth_formations_count: int = 0

## Size of the largest earth formation in the panel
var largest_earth_formation_size: int = 0

## Lines/columns entirely filled by a single element (GameEnums.Element → int)
var element_full_rows_cols: Dictionary = {}

# --- Data requiring new tracking (Fase 2) ---

## Number of complete cycles of 5 distinct consecutive elements (O Dançarino)
var element_cycles_completed: int = 0

## Number of runes that were NOT moved during the planning phase (O Baluarte)
var runes_not_moved_count: int = 0

## Number of infinite loops detected by the reader (O Retorno)
var infinite_loops_count: int = 0


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

## Build a BattleRoundStatistics snapshot from the current BattleContext and GridManager.
## Call this right after the Reader finishes its sequence, before resetting state.
static func build_from(context: BattleContext, grid: GridManager) -> BattleRoundStatistics:
	var stats = BattleRoundStatistics.new()

	# --- From BattleContext ---
	stats.activation_history = context.activation_history.duplicate(true)
	stats.runes_destroyed_count = context.runes_destroyed_this_round
	stats.runes_created_count = context.runes_created_this_round
	stats.unique_runes_count = context.get_unique_runes_count()
	stats.total_activations = context.get_total_activations_this_round()

	# Activations by element
	stats.activations_by_element = _count_activations_by_element(context.activation_history)
	stats.simultaneous_runes_activated_count = _count_simultaneous_unique_runes(context.activation_history)
	stats.successful_conditions_count = context.successful_conditions_count
	stats.mana_anomalies_created_count = context.mana_anomalies_created_count

	# --- From GridManager ---
	_compute_grid_stats(stats, grid)

	# --- New tracking fields ---
	stats.element_cycles_completed = context.element_cycles_completed
	stats.runes_not_moved_count = context.runes_not_moved_count
	stats.infinite_loops_count = context.infinite_loops_detected

	return stats


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

static func _count_activations_by_element(history: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {}
	for entry in history:
		var elements: Array = entry.get("elements", [])
		for elem in elements:
			counts[elem] = counts.get(elem, 0) + 1
	return counts


static func _count_simultaneous_unique_runes(history: Array[Dictionary]) -> int:
	var unique_runes: Dictionary = {}
	for entry in history:
		var batch_id: int = entry.get("simultaneous_batch_id", -1)
		if batch_id < 0:
			continue
		var rune_instance: RuneInstance = entry.get("rune_instance")
		if rune_instance:
			unique_runes[rune_instance.get_instance_id()] = true
			continue
		var rune_id = entry.get("rune_id", "")
		var slot_pos: Vector2i = entry.get("slot_position", Vector2i(-1, -1))
		var fallback_key := "%s@%s@%d" % [str(rune_id), str(slot_pos), batch_id]
		unique_runes[fallback_key] = true
	return unique_runes.size()


static func _compute_grid_stats(stats: BattleRoundStatistics, grid: GridManager) -> void:
	var slot_type_set: Dictionary = {}  # unique slot types
	var element_rows: Dictionary = {}   # Element → count of full rows
	var element_cols: Dictionary = {}   # Element → count of full cols

	for slot in grid.grid:
		# Empty slots
		if slot.is_empty():
			stats.empty_slots_count += 1
		else:
			# Remaining activations
			var rune: RuneInstance = slot.rune
			if rune:
				var remaining := rune.get_max_activations() - rune.current_activations
				stats.remaining_activations_total += max(remaining, 0)
				if rune.data and rune.data.rarity >= GameEnums.Rarity.RARE:
					stats.rare_plus_runes_in_panel += 1

		# Residue check — a slot "has residue" if it has any active states
		if slot.slot and not slot.slot.active_states.is_empty():
			stats.slots_with_residue += 1

		# Distinct slot types
		if slot.slot:
			var mod_id = slot.slot.slot_modifier_id
			if mod_id and not mod_id.is_empty():
				slot_type_set[mod_id] = true

	stats.distinct_slot_types = slot_type_set.size()

	# Full rows / full columns by element
	for y in range(GridManager.GRID_SIZE):
		_check_line_for_element(grid.get_row(y), element_rows)
	for x in range(GridManager.GRID_SIZE):
		_check_line_for_element(grid.get_column(x), element_cols)

	# Merge rows + cols into one dict
	var merged: Dictionary = {}
	for elem in element_rows:
		merged[elem] = merged.get(elem, 0) + element_rows[elem]
	for elem in element_cols:
		merged[elem] = merged.get(elem, 0) + element_cols[elem]
	stats.element_full_rows_cols = merged

	_compute_earth_formation_stats(stats, grid)


static func _compute_earth_formation_stats(stats: BattleRoundStatistics, grid: GridManager) -> void:
	var visited: Dictionary = {}
	for slot in grid.grid:
		if not _is_earth_rune_slot(slot):
			continue
		var coord: Vector2i = slot.grid_position
		if visited.has(coord):
			continue
		var cluster_size := _flood_fill_earth_cluster(grid, coord, visited)
		if cluster_size < 2:
			continue
		stats.earth_formations_count += 1
		if cluster_size > stats.largest_earth_formation_size:
			stats.largest_earth_formation_size = cluster_size


static func _flood_fill_earth_cluster(grid: GridManager, start_coord: Vector2i, visited: Dictionary) -> int:
	var cluster_size := 0
	var queue: Array[Vector2i] = []
	queue.append(start_coord)

	while not queue.is_empty():
		var coord: Vector2i = queue.pop_front()
		if visited.has(coord):
			continue
		visited[coord] = true

		var slot: GridSlot = grid.get_slot(coord)
		if not _is_earth_rune_slot(slot):
			continue

		cluster_size += 1

		for neighbor in grid.get_neighbors(coord, false):
			if not neighbor:
				continue
			if visited.has(neighbor.grid_position):
				continue
			if _is_earth_rune_slot(neighbor):
				queue.append(neighbor.grid_position)

	return cluster_size


static func _is_earth_rune_slot(slot: GridSlot) -> bool:
	if not slot or slot.is_void() or slot.is_empty():
		return false
	return GameEnums.has_element(slot.rune.get_elements(), GameEnums.Element.EARTH)


## Check if an entire line (row or column) is occupied by runes sharing a single element.
## If so, increment the count for that element in the given dictionary.
static func _check_line_for_element(line: Array[GridSlot], out_dict: Dictionary) -> void:
	if line.is_empty():
		return

	# All slots must have a rune
	for slot in line:
		if slot.is_empty():
			return

	# Collect the intersection of elements across all runes in the line
	var common_elements: Array = []
	var first := true
	for slot in line:
		var rune_elements: Array = slot.rune.get_elements()
		if first:
			common_elements = rune_elements.duplicate()
			first = false
		else:
			var next_common: Array = []
			for elem in common_elements:
				if elem in rune_elements:
					next_common.append(elem)
			common_elements = next_common
		if common_elements.is_empty():
			return

	# Each common element gets +1 line
	for elem in common_elements:
		out_dict[elem] = out_dict.get(elem, 0) + 1


# ---------------------------------------------------------------------------
# Convenience getters
# ---------------------------------------------------------------------------

## Get activations for a specific element
func get_element_activations(element: GameEnums.Element) -> int:
	return activations_by_element.get(element, 0)


## Get full rows+cols count for a specific element
func get_element_lines(element: GameEnums.Element) -> int:
	return element_full_rows_cols.get(element, 0)


## Returns true when every present element has the same activation count (O Equilibrista)
func is_element_balanced() -> bool:
	if activations_by_element.is_empty():
		return false
	var counts: Array = activations_by_element.values()
	var first_count: int = counts[0]
	for c in counts:
		if c != first_count:
			return false
	return true
