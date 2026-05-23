class_name BattleContext
extends RefCounted

## A context object passed through the effect chain during execution.
## Acts as the API for effects to interact with the game state (Grid, Score, etc.)
## without coupling directly to Nodes like Reader or Main.
## 
## Tracks round state for rune effects that depend on:
## - Previous activations and their elements
## - Destroyed/created runes this round
## - Unique runes activated
## - Visited slots for reader jumps

signal score_event(amount: int, source: RuneInstance)
signal reader_jump_request(index: int)
signal rune_activation_queued(slot: GridSlot)
signal rune_destroyed(slot: GridSlot, rune: RuneInstance)
signal rune_created(slot: GridSlot, rune: RuneInstance)

var grid: GridManager
var current_score: int = 0
var current_step_index: int = 0
var queued_activations: Array[GridSlot] = []

## Ordered list of coordinates the reader will traverse this round
var reader_path: Array[Vector2i] = []

## Tracking for event generation
var current_slot: GridSlot = null
var current_rune: RuneInstance = null
var effects_this_activation: Array[Dictionary] = []  # Track effect results

## Reference to EventBus (optional, for direct event emission)
var event_bus: Node = null

# --- Round State Tracking (for new rune effects) ---

## History of activations this round: [{elements, rune_id, slot_position, rune_instance}]
var activation_history: Array[Dictionary] = []

## Count of runes destroyed this round
var runes_destroyed_this_round: int = 0

## Count of runes created this round
var runes_created_this_round: int = 0

## Unique runes activated this round (rune_id -> activation count)
var unique_runes_activated: Dictionary = {}

## Slots visited by the reader this round (indices)
var visited_slots: Array[int] = []

## Runes marked for resurrection at end of round (e.g., Phoenix)
var runes_to_resurrect: Array[Dictionary] = []  # [{rune_data, slot_position, permanent_buffs}]

## Number of complete cycles of 5 distinct elements (O Dançarino)
var element_cycles_completed: int = 0

## Planning phase movement tracking
var runes_moved_this_round: int = 0
var runes_not_moved_count: int = 0

## Number of infinite loops detected by reader jumps
var infinite_loops_detected: int = 0

## Number of successful condition evaluations this round
var successful_conditions_count: int = 0

## Number of mana anomalies created this round
var mana_anomalies_created_count: int = 0

## Mana tracking for mana residue / mana anomaly
var current_mana: int = 0

## Simultaneous activation tracking
var _simultaneous_batch_active: bool = false
var _simultaneous_batch_id: int = 0

## Per-element activation count this round: { Element -> int }
var element_activation_counts: Dictionary = {}

## Per-rune movement tracking: { rune_instance_id -> times_moved }
var rune_move_counts: Dictionary = {}

## Tracks which RID was the last activated rune's instance, for consecutive detection
var _last_activated_rune_instance: RuneInstance = null


func _init(p_grid: GridManager):
	grid = p_grid
	# Try to get EventBus
	if Engine.has_singleton("EventBus"):
		event_bus = Engine.get_singleton("EventBus")


## Update the traversal order for this battle
func set_reader_path(path: Array[Vector2i]) -> void:
	reader_path = path.duplicate()


## Get the traversal length (number of valid slots)
func get_reader_path_length() -> int:
	return reader_path.size()


## Get the coordinate at a traversal index
func get_reader_coord(index: int) -> Vector2i:
	if index < 0 or index >= reader_path.size():
		return Vector2i(-1, -1)
	return reader_path[index]


## Find traversal index for a given coordinate (-1 if not present)
func find_reader_index(coord: Vector2i) -> int:
	for i in range(reader_path.size()):
		if reader_path[i] == coord:
			return i
	return -1


## Resets round-specific tracking. Call at start of each round.
func reset_round_state() -> void:
	activation_history.clear()
	runes_destroyed_this_round = 0
	runes_created_this_round = 0
	unique_runes_activated.clear()
	visited_slots.clear()
	runes_to_resurrect.clear()
	element_cycles_completed = 0
	runes_moved_this_round = 0
	runes_not_moved_count = 0
	infinite_loops_detected = 0
	successful_conditions_count = 0
	mana_anomalies_created_count = 0
	current_mana = 0
	_simultaneous_batch_active = false
	_simultaneous_batch_id = 0
	element_activation_counts.clear()
	rune_move_counts.clear()
	_last_activated_rune_instance = null
	set_meta("total_activations", 0)


## Set the current slot/rune being processed (called by Reader before activation)
func set_current_context(slot: GridSlot, rune: RuneInstance) -> void:
	current_slot = slot
	current_rune = rune
	effects_this_activation.clear()


## Record an effect execution result (called after each effect)
func record_effect_result(effect: Resource, success: bool, score_delta: int, targets: Array[GridSlot]) -> void:
	effects_this_activation.append({
		"effect": effect,
		"success": success,
		"score_delta": score_delta,
		"targets": targets.map(func(s): return s.grid_position)
	})


func add_score(amount: int, source: RuneInstance) -> void:
	# Apply slot multiplier if there's a current slot
	var final_amount = amount
	if current_slot:
		var multiplier = current_slot.get_multiplier()
		final_amount = int(amount * multiplier)
	score_event.emit(final_amount, source)


func multiply_global_score(factor: float) -> void:
	# This is a special event, we might handle it by adding the difference
	var added = int(current_score * (factor - 1.0))
	if added != 0:
		score_event.emit(added, null) # Source null or a special "Global" source


func request_reader_jump(target_index: int) -> void:
	reader_jump_request.emit(target_index)


func queue_rune_activation(slot: GridSlot) -> void:
	if slot not in queued_activations:
		queued_activations.append(slot)
		rune_activation_queued.emit(slot)


func get_and_clear_queued_activations() -> Array[GridSlot]:
	var result = queued_activations.duplicate()
	queued_activations.clear()
	return result


## Get accumulated effect results for event generation
func get_effects_results() -> Array[Dictionary]:
	return effects_this_activation.duplicate()


## Clear effect tracking for next activation
func clear_effects_tracking() -> void:
	effects_this_activation.clear()
	current_slot = null
	current_rune = null


# --- Activation History Methods ---

## Records a rune activation in history. Called by Reader after activation.
func record_activation(rune: RuneInstance, slot: GridSlot) -> void:
	var entry = {
		"elements": GameEnums.normalize_elements(rune.get_elements()),
		"rune_id": rune.data.id,
		"slot_position": slot.grid_position,
		"rune_instance": rune,
		"simultaneous_batch_id": get_simultaneous_batch_id()
	}
	activation_history.append(entry)
	_update_element_cycles()
	_track_element_activations(rune)
	_last_activated_rune_instance = rune
	
	# Track unique runes
	var rune_id = rune.data.id
	if unique_runes_activated.has(rune_id):
		unique_runes_activated[rune_id] += 1
	else:
		unique_runes_activated[rune_id] = 1
	
	# Track visited slot using traversal index when available
	var slot_index = current_step_index if current_step_index >= 0 else slot.grid_position.y * GridManager.GRID_SIZE + slot.grid_position.x
	if slot_index not in visited_slots:
		visited_slots.append(slot_index)


## Record a reader jump. If it goes to a visited slot, count as an infinite loop.
func record_reader_jump(target_index: int) -> void:
	if target_index in visited_slots:
		infinite_loops_detected += 1


## Record an infinite loop detected by the InfiniteLoopDetector.
## Called by Reader when a cyclic pattern is confirmed and broken.
func record_infinite_loop(loop_data: Dictionary) -> void:
	infinite_loops_detected += 1
	var cycle_length: int = loop_data.get("cycle_length", 0)
	print("[BattleContext] Infinite loop #%d recorded: %d runes in cycle" % [
		infinite_loops_detected, cycle_length
	])


## Analyze planning events to compute how many runes were moved.
## This should be called once at battle start.
func analyze_planning_movements(planning_events: Array[PlanningEvent], grid_manager: GridManager) -> void:
	var moved_coords: Dictionary = {}
	for event in planning_events:
		if event == null:
			continue
		match event.action_type:
			PlanningEvent.ActionType.MOVE_RUNE:
				if event.source_location is Vector2i:
					moved_coords[event.source_location] = true
				if event.destination_location is Vector2i:
					moved_coords[event.destination_location] = true
			PlanningEvent.ActionType.SWAP_RUNES:
				if event.source_location is Vector2i:
					moved_coords[event.source_location] = true
				if event.destination_location is Vector2i:
					moved_coords[event.destination_location] = true
				if event.swap_source is Vector2i:
					moved_coords[event.swap_source] = true
			PlanningEvent.ActionType.ROTATE_RUNES:
				if event.source_location is Vector2i:
					moved_coords[event.source_location] = true
				if event.destination_location is Vector2i:
					moved_coords[event.destination_location] = true
			PlanningEvent.ActionType.PLACE_RUNE:
				if event.destination_location is Vector2i:
					moved_coords[event.destination_location] = true
			PlanningEvent.ActionType.REMOVE_RUNE:
				if event.source_location is Vector2i:
					moved_coords[event.source_location] = true
			_:
				pass

	var total_runes := 0
	var moved_runes := 0
	for slot in grid_manager.grid:
		if slot.is_empty():
			continue
		total_runes += 1
		if moved_coords.has(slot.grid_position):
			moved_runes += 1

	runes_moved_this_round = moved_runes
	runes_not_moved_count = max(total_runes - moved_runes, 0)


## Update element cycle count based on the last 5 activations.
## A cycle is counted when the last 5 activations are all single-element
## and contain all 5 distinct base elements with no repeats.
## Uses a non-overlapping window: only checks every 5th activation after
## the last counted cycle to avoid double-counting.
func _update_element_cycles() -> void:
	var window_start := element_cycles_completed * 5
	var window_end := window_start + 5
	if activation_history.size() < window_end:
		return
	var window = activation_history.slice(window_start, window_end)
	var seen: Dictionary = {}
	for entry in window:
		var elements: Array = entry.get("elements", [])
		if elements.size() != 1:
			return
		var elem = elements[0]
		if seen.has(elem):
			return
		seen[elem] = true
	if seen.size() == GameEnums.BASE_ELEMENTS.size():
		element_cycles_completed += 1
		# Recursively check next window in case multiple cycles completed
		_update_element_cycles()


## Returns the elements of the last activated rune, or an empty array if none
func get_last_activated_elements() -> Array[GameEnums.Element]:
	if activation_history.is_empty():
		return []
	return activation_history[-1].get("elements", [])

## Backward-compatible helper that returns the first element or -1 if none exist
func get_last_activated_element() -> int:
	var elements = get_last_activated_elements()
	return elements[0] if elements.size() > 0 else -1


## Returns the last N activation entries
func get_last_n_activations(n: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start_idx = max(0, activation_history.size() - n)
	for i in range(start_idx, activation_history.size()):
		result.append(activation_history[i])
	return result


## Checks if the last N activations share at least one common element
func last_n_same_element(n: int) -> bool:
	return not get_common_elements_of_last_n(n).is_empty()


## Returns the intersection of elements across the last N activations
func get_common_elements_of_last_n(n: int) -> Array[GameEnums.Element]:
	if activation_history.size() < n:
		return []
	var last_n = get_last_n_activations(n)
	if last_n.is_empty():
		return []
	var common: Array[GameEnums.Element] = GameEnums.normalize_elements(last_n[0].get("elements", []))
	for entry in last_n:
		var elements = GameEnums.normalize_elements(entry.get("elements", []))
		var next_common: Array[GameEnums.Element] = []
		for elem in common:
			if elem in elements:
				next_common.append(elem)
		common = next_common
		if common.is_empty():
			return []
	return common

## Legacy helper to keep existing signatures functioning
func get_common_element_of_last_n(n: int) -> int:
	var elements = get_common_elements_of_last_n(n)
	return elements[0] if elements.size() > 0 else -1


## Returns total number of activations this round
func get_total_activations_this_round() -> int:
	return activation_history.size()


## Returns count of unique individual runes activated
func get_unique_runes_count() -> int:
	return unique_runes_activated.size()


## Returns a random visited slot index, or -1 if none
func get_random_visited_slot() -> int:
	if visited_slots.is_empty():
		return -1
	return visited_slots[randi() % visited_slots.size()]


# --- Rune Creation/Destruction Tracking ---

## Called when a rune is destroyed during the round
func on_rune_destroyed(slot: GridSlot, rune: RuneInstance) -> void:
	runes_destroyed_this_round += 1
	rune_destroyed.emit(slot, rune)
	
	# Check if rune should resurrect (e.g., Phoenix)
	if rune.get_meta("should_resurrect", false):
		runes_to_resurrect.append({
			"rune_data": rune.data,
			"slot_position": slot.grid_position,
			"permanent_buffs": rune.permanent_buffs.duplicate(),
			"permanent_elements": rune.permanent_elements.duplicate()
		})


## Called when a rune is created during the round
func on_rune_created(slot: GridSlot, rune: RuneInstance) -> void:
	runes_created_this_round += 1
	rune_created.emit(slot, rune)


## Mark a rune to resurrect at end of round
func mark_for_resurrection(rune: RuneInstance, slot: GridSlot, bonus_permanent_score: int = 0) -> void:
	var buffs = rune.permanent_buffs.duplicate()
	buffs["score_bonus"] = buffs.get("score_bonus", 0) + bonus_permanent_score
	runes_to_resurrect.append({
		"rune_data": rune.data,
		"slot_position": slot.grid_position,
		"permanent_buffs": buffs,
		"permanent_elements": rune.permanent_elements.duplicate()
	})


## Process resurrections at end of round
func process_resurrections() -> void:
	for entry in runes_to_resurrect:
		var slot = grid.get_slot(entry.slot_position)
		if slot and slot.is_empty():
			var new_rune = RuneInstance.new(entry.rune_data)
			for key in entry.permanent_buffs:
				new_rune.permanent_buffs[key] = entry.permanent_buffs[key]
			if entry.has("permanent_elements"):
				new_rune.permanent_elements = entry.permanent_elements.duplicate()
			slot.set_rune(new_rune)
			grid.slot_changed.emit(slot.grid_position)
			print("Resurrected %s at %s with buffs" % [entry.rune_data.rune_name, str(entry.slot_position)])
	runes_to_resurrect.clear()


# --- Economy Methods ---

## Add money (emits EconomyEvent through EventBus)
func add_money(amount: int, source: RuneInstance = null) -> void:
	if not event_bus:
		var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
		if root:
			event_bus = root.get_node_or_null("EventBus")
	
	if event_bus:
		var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
		var stats = root.get_node_or_null("Stats") if root else null
		if stats:
			var balance = stats.get_money()
			var rune_id: StringName = source.data.id if source and source.data else &"unknown"
			var economy_event = EconomyEvent.create_rune_income(rune_id, amount, balance)
			event_bus.emit(economy_event)


## Remove money (returns true if successful, false if not enough)
func remove_money(amount: int, source: RuneInstance = null) -> bool:
	if not event_bus:
		var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
		if root:
			event_bus = root.get_node_or_null("EventBus")
	
	if event_bus:
		var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
		var stats = root.get_node_or_null("Stats") if root else null
		if stats:
			var balance = stats.get_money()
			if balance < amount:
				return false
			var rune_id: StringName = source.data.id if source and source.data else &"cost"
			var economy_event = EconomyEvent.new()
			economy_event.transaction_type = EconomyEvent.TransactionType.COST
			economy_event.source = rune_id
			economy_event.amount = -amount
			economy_event.balance_before = balance
			economy_event.balance_after = balance - amount
			event_bus.emit(economy_event)
			return true
	return false


## Get current money balance
func get_money() -> int:
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root:
		var stats_node = root.get_node_or_null("Stats")
		if stats_node and stats_node.has_method("get_money"):
			return stats_node.get_money()
	return 0


# --- Mana Methods ---

## Add mana from mana residue pickup
func add_mana(amount: int) -> void:
	current_mana += amount

## Remove mana (from anomaly). Returns actual amount removed.
func remove_mana(amount: int) -> int:
	var removed = mini(current_mana, amount)
	current_mana -= amount
	return removed


## Record a successful condition evaluation during this round.
func record_successful_condition() -> void:
	successful_conditions_count += 1


## Record created residues relevant for relic statistics.
func record_residue_created(residue_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	if residue_id == "mana_anomaly":
		mana_anomalies_created_count += amount


# --- Simultaneous Activation Tracking ---

## Start a simultaneous activation batch
func begin_simultaneous_batch() -> void:
	_simultaneous_batch_id += 1
	_simultaneous_batch_active = true

## End simultaneous activation batch
func end_simultaneous_batch() -> void:
	_simultaneous_batch_active = false

## Check if currently in a simultaneous batch
func is_simultaneous_active() -> bool:
	return _simultaneous_batch_active

## Get the current simultaneous batch ID
func get_simultaneous_batch_id() -> int:
	return _simultaneous_batch_id if _simultaneous_batch_active else -1


# --- Element Activation Tracking ---

## Record per-element activation counts (called from record_activation)
func _track_element_activations(rune: RuneInstance) -> void:
	for elem in rune.get_elements():
		element_activation_counts[elem] = element_activation_counts.get(elem, 0) + 1

## Get the number of activations for a specific element this round
func get_element_activation_count(element: GameEnums.Element) -> int:
	return element_activation_counts.get(element, 0)

## Get total activations for any of the given elements this round
func get_elements_activation_count(elements: Array[GameEnums.Element]) -> int:
	var total = 0
	for elem in elements:
		total += element_activation_counts.get(elem, 0)
	return total


# --- Consecutive Activation Tracking ---

## Check if the last activated rune instance is the same as the given one
func was_consecutive_activation(rune: RuneInstance) -> bool:
	return _last_activated_rune_instance == rune

## Get the rune instance that was activated just before the current one (in reader order)
func get_previous_activated_rune() -> RuneInstance:
	if activation_history.size() < 2:
		return null
	return activation_history[-2].get("rune_instance")


# --- Rune Movement Tracking ---

## Record that a specific rune was moved (call during planning phase analysis)
func record_rune_moved(rune: RuneInstance) -> void:
	var rid = rune.get_instance_id() if rune else 0
	rune_move_counts[rid] = rune_move_counts.get(rid, 0) + 1

## Get how many times a specific rune was moved this round
func get_rune_move_count(rune: RuneInstance) -> int:
	var rid = rune.get_instance_id() if rune else 0
	return rune_move_counts.get(rid, 0)


# --- Residue Queries ---

## Count slots with a specific residue type in the panel
func count_panel_residue(residue_id: String) -> int:
	if not grid:
		return 0
	var count = 0
	for slot in grid.grid:
		if slot.is_void():
			continue
		if slot.slot and slot.slot.has_specific_residue(residue_id):
			count += 1
	return count

## Find the nearest slot with a specific residue relative to reader position
func find_nearest_residue_slot(residue_id: String, from_step_index: int, search_backwards: bool = true) -> int:
	if reader_path.is_empty() or not grid:
		return -1
	if search_backwards:
		for i in range(from_step_index - 1, -1, -1):
			var coord = get_reader_coord(i)
			var slot = grid.get_slot(coord)
			if slot and slot.slot and slot.slot.has_specific_residue(residue_id):
				return i
	else:
		for i in range(from_step_index + 1, reader_path.size()):
			var coord = get_reader_coord(i)
			var slot = grid.get_slot(coord)
			if slot and slot.slot and slot.slot.has_specific_residue(residue_id):
				return i
	return -1
