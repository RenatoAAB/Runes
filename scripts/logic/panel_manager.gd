class_name PanelManager
extends Node

## Manages multiple panels and coordinates their execution.
## Handles panel switching, score aggregation, and multi-panel battles.
##
## Final Score Formula: Score = Panel1 × Panel2 × Panel3 × ...
## Each panel calculates its own score independently, then all are multiplied.

signal panel_added(panel: PanelInstance)
signal panel_unlocked(panel: PanelInstance)
signal panel_switched(from_index: int, to_index: int)
signal panel_battle_started(panel_index: int)
signal panel_battle_completed(panel_index: int, score: int)
signal all_panels_completed(final_score: int)
signal panel_score_updated(panel_index: int, score: int)
signal panel_reset()

## All panels in the game (unlocked or not)
var panels: Array[PanelInstance] = []

## Currently active/visible panel index
var active_panel_index: int = 0

## Panel currently being processed in battle
var battle_panel_index: int = 0

## Is a multi-panel battle in progress?
var is_battle_running: bool = false

## Scores from completed panels (during battle)
var panel_scores: Array[int] = []

## Reference to EventBus
var event_bus: Node = null
var reader_step_delay: float = -1.0


func _get_scene_reader_delay(parent_node: Node) -> float:
	if not parent_node:
		return -1.0
	# Check direct children for an existing Reader instance to mirror its step_delay
	for child in parent_node.get_children():
		if child is Reader:
			return child.step_delay
	return -1.0


func _ready() -> void:
	if has_node("/root/EventBus"):
		event_bus = get_node("/root/EventBus")


## Initialize with default panel configuration
func initialize_default() -> void:
	if panels.size() > 0:
		print("[PanelManager] Already initialized with %d panels" % panels.size())
		return  # Already initialized
	
	print("[PanelManager] Creating default panel configuration...")
	
	# Create the first panel (always unlocked)
	var first_panel_data = _create_default_panel_data(0)
	var first_panel = PanelInstance.new(first_panel_data, 0)
	first_panel.is_unlocked = true
	add_panel(first_panel)
	
	# Create additional locked panels (can be unlocked with money)
	for i in range(1, 3):  # 3 panels total
		var panel_data = _create_default_panel_data(i)
		var panel = PanelInstance.new(panel_data, i)
		add_panel(panel)
	
	print("[PanelManager] Created %d panels (1 unlocked, %d locked)" % [panels.size(), panels.size() - 1])


## Create default panel data for a given index
func _create_default_panel_data(index: int) -> PanelData:
	var data = PanelData.new()
	data.id = "panel_%d" % index
	data.display_name = "Panel %d" % (index + 1)
	data.base_size = Vector2i(3, 3)
	data.max_size = Vector2i(5, 5)
	data.unlocked_by_default = (index == 0)
	data.unlock_cost = 25 + (index * 10)  # 25, 35, 45...
	data.max_relics = 3
	return data


## Add a panel to the manager
func add_panel(panel: PanelInstance) -> void:
	panel.panel_index = panels.size()
	panels.append(panel)
	panel_added.emit(panel)
	
	# Connect panel signals
	if panel.reader:
		panel.reader.sequence_finished.connect(_on_panel_sequence_finished.bind(panel.panel_index))
		panel.reader.score_updated.connect(_on_panel_score_updated.bind(panel.panel_index))


## Get a panel by index
func get_panel(index: int) -> PanelInstance:
	if index >= 0 and index < panels.size():
		return panels[index]
	return null


## Get the currently active panel
func get_active_panel() -> PanelInstance:
	return get_panel(active_panel_index)


## Get all unlocked panels
func get_unlocked_panels() -> Array[PanelInstance]:
	var unlocked: Array[PanelInstance] = []
	for panel in panels:
		if panel.is_unlocked:
			unlocked.append(panel)
	return unlocked


## Get the count of unlocked panels
func get_unlocked_panel_count() -> int:
	var count = 0
	for panel in panels:
		if panel.is_unlocked:
			count += 1
	return count


## Switch to a different panel (for editing/viewing)
func switch_to_panel(index: int) -> bool:
	if index < 0 or index >= panels.size():
		return false
	
	var panel = panels[index]
	if not panel.is_unlocked:
		return false
	
	var old_index = active_panel_index
	active_panel_index = index
	panel_switched.emit(old_index, index)
	return true


## Unlock a panel (usually requires payment)
func unlock_panel(index: int) -> bool:
	if index < 0 or index >= panels.size():
		return false
	
	var panel = panels[index]
	if panel.is_unlocked:
		return false  # Already unlocked
	
	panel.is_unlocked = true
	panel_unlocked.emit(panel)
	return true


## Get the unlock cost for a panel
func get_panel_unlock_cost(index: int) -> int:
	var panel = get_panel(index)
	if panel and panel.data:
		return panel.data.unlock_cost
	return -1


## Setup grid and reader for all unlocked panels
func setup_all_panels(parent_node: Node, p_step_delay: float = -1.0) -> void:
	var effective_delay = reader_step_delay
	if p_step_delay >= 0.0:
		effective_delay = p_step_delay
	elif effective_delay < 0.0:
		effective_delay = _get_scene_reader_delay(parent_node)
	reader_step_delay = effective_delay

	for panel in panels:
		if panel.is_unlocked:
			panel.setup_grid_and_reader(parent_node, reader_step_delay)


# --- Battle Flow ---

## Start a battle across all unlocked panels
func start_multi_panel_battle() -> void:
	if is_battle_running:
		push_warning("Battle already in progress")
		return

	# Ensure grids/readers exist for unlocked panels before battle
	setup_all_panels(get_parent(), reader_step_delay)
	
	is_battle_running = true
	panel_scores.clear()
	battle_panel_index = 0
	
	# Find first unlocked panel
	while battle_panel_index < panels.size() and not panels[battle_panel_index].is_unlocked:
		battle_panel_index += 1
	
	if battle_panel_index >= panels.size():
		# No unlocked panels
		is_battle_running = false
		all_panels_completed.emit(0)
		return
	
	# Notify EventBus
	if event_bus and event_bus.has_method("begin_battle"):
		event_bus.begin_battle(get_unlocked_panel_count())
	
	_start_current_panel_battle()


## Start battle on the current panel
func _start_current_panel_battle() -> void:
	var panel = panels[battle_panel_index]

	# Ensure reader targets this panel's grid
	if panel.reader:
		panel.reader.grid_manager = panel.grid_manager
	
	if event_bus and event_bus.has_method("begin_panel"):
		event_bus.begin_panel(battle_panel_index)
	
	panel_battle_started.emit(battle_panel_index)
	panel.reset_for_battle()
	
	# Connect to reader if not already
	if panel.reader and not panel.reader.sequence_finished.is_connected(_on_panel_sequence_finished):
		panel.reader.sequence_finished.connect(_on_panel_sequence_finished.bind(battle_panel_index))
	if panel.reader and not panel.reader.score_updated.is_connected(_on_panel_score_updated):
		panel.reader.score_updated.connect(_on_panel_score_updated.bind(battle_panel_index))
	
	panel.start_battle()


## Handle panel battle completion
func _on_panel_sequence_finished(score: int, panel_index: int) -> void:
	var panel = panels[panel_index]
	var final_panel_score = int(panel.calculate_final_score())
	
	panel_scores.append(final_panel_score)
	panel_battle_completed.emit(panel_index, final_panel_score)
	
	# Move to next unlocked panel
	battle_panel_index += 1
	while battle_panel_index < panels.size() and not panels[battle_panel_index].is_unlocked:
		battle_panel_index += 1
	
	if battle_panel_index >= panels.size():
		# All panels completed
		_finish_multi_panel_battle()
	else:
		# Start next panel
		_start_current_panel_battle()


## Handle panel score updates during battle
func _on_panel_score_updated(score: int, panel_index: int) -> void:
	var panel = panels[panel_index]
	panel.current_score = score
	panel_score_updated.emit(panel_index, score)


## Finish the multi-panel battle and calculate final score
func _finish_multi_panel_battle() -> void:
	is_battle_running = false
	
	var final_score = calculate_multi_panel_score()
	
	if event_bus and event_bus.has_method("end_battle"):
		# Get target from game manager
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		var target = 0
		if game_manager:
			target = game_manager.current_target_score
		event_bus.end_battle(target)
	
	all_panels_completed.emit(final_score)


## Calculate the final score from all panel scores
## Formula: Score = Panel1 × Panel2 × Panel3 × ...
## Panels with score 0 are treated as 1 to avoid zeroing everything
func calculate_multi_panel_score() -> int:
	if panel_scores.is_empty():
		return 0
	
	# If only one panel, return its score directly
	if panel_scores.size() == 1:
		return panel_scores[0]
	
	# Multiply all panel scores
	# Treat 0 as 1 to avoid zeroing the entire result
	var result: float = 1.0
	for score in panel_scores:
		var panel_value = maxf(score, 1.0)
		result *= panel_value
	
	return int(result)


## Get individual panel scores (for display)
func get_panel_scores() -> Array[int]:
	return panel_scores.duplicate()


## Get a breakdown of the score calculation
func get_score_breakdown() -> Dictionary:
	var breakdown = {
		"panel_scores": panel_scores.duplicate(),
		"final_score": calculate_multi_panel_score(),
		"formula": _get_score_formula_string()
	}
	return breakdown


## Get the score formula as a display string
func _get_score_formula_string() -> String:
	if panel_scores.is_empty():
		return "0"
	
	if panel_scores.size() == 1:
		return str(panel_scores[0])
	
	var parts: Array[String] = []
	for score in panel_scores:
		parts.append(str(score))
	
	return " × ".join(parts) + " = " + str(calculate_multi_panel_score())


# --- Panel Grid Access (for compatibility) ---

## Get the grid manager of the active panel
func get_active_grid_manager() -> GridManager:
	var panel = get_active_panel()
	if panel:
		return panel.grid_manager
	return null


## Get the reader of the active panel
func get_active_reader() -> Reader:
	var panel = get_active_panel()
	if panel:
		return panel.reader
	return null


## Reset all panels for a new game/run
func reset_all_panels() -> void:
	for panel in panels:
		panel.reset_for_battle()
		panel.current_score = 0
		panel.attached_relics.clear()
		panel._recalculate_relic_multiplier()
	
	panel_scores.clear()
	is_battle_running = false
	active_panel_index = 0
	battle_panel_index = 0


## Full reset all panels for game over - resets slots to initial 3x3
func full_reset_all_panels() -> void:
	for panel in panels:
		panel.full_reset()
	
	panel_scores.clear()
	is_battle_running = false
	active_panel_index = 0
	battle_panel_index = 0
	panel_reset.emit()


## Clear all panels (for complete reset)
func clear_all_panels() -> void:
	for panel in panels:
		if panel.grid_manager and is_instance_valid(panel.grid_manager):
			panel.grid_manager.queue_free()
		if panel.reader and is_instance_valid(panel.reader):
			panel.reader.queue_free()
	
	panels.clear()
	panel_scores.clear()
	active_panel_index = 0
	battle_panel_index = 0
	is_battle_running = false


## Get summary of all panels
func get_all_panels_summary() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for panel in panels:
		summaries.append(panel.get_summary())
	return summaries
