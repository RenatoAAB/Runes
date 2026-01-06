class_name PanelInstance
extends RefCounted

## Runtime instance of a Panel.
## Each panel has its own grid, reader, and context for independent score calculation.
## Multiple panels multiply their scores together for the final result.

signal panel_score_changed(new_score: int)
signal slot_unlocked(coord: Vector2i)
signal relic_attached(relic: RefCounted)  # RelicInstance
signal relic_detached(relic: RefCounted)  # RelicInstance

var data: PanelData

## Panel index in the game (0 = first panel)
var panel_index: int = 0

## Is this panel unlocked and usable?
var is_unlocked: bool = false

## The grid manager for this panel
var grid_manager: GridManager = null

## The reader for this panel
var reader: Reader = null

## The battle context for this panel
var battle_context: BattleContext = null

## Which slots are unlocked (can hold runes)
## Key: Vector2i coordinate, Value: bool (true = unlocked)
var unlocked_slots: Dictionary = {}

## Attached relics (affects all activations in this panel)
var attached_relics: Array = []  # Array[RelicInstance] - will be typed when RelicInstance exists

## Current score for this panel (during battle)
var current_score: int = 0

## Accumulated multiplier from relics and other sources
var relic_multiplier: float = 1.0

## Upgrade level of the panel itself
var upgrade_level: int = 0


func _init(p_data: PanelData = null, p_index: int = 0):
	panel_index = p_index
	
	if p_data:
		data = p_data
		is_unlocked = data.unlocked_by_default
	else:
		data = _create_default_panel_data()
		is_unlocked = true
	
	_initialize_unlocked_slots()


## Create a default panel configuration
static func _create_default_panel_data() -> PanelData:
	var default = PanelData.new()
	default.id = "default_panel"
	default.display_name = "Panel"
	default.base_size = Vector2i(3, 3)
	default.max_size = Vector2i(5, 5)
	default.unlocked_by_default = true
	default.max_relics = 3
	return default


## Initialize the unlocked slots based on panel data
func _initialize_unlocked_slots() -> void:
	unlocked_slots.clear()
	
	# Initialize all slots as locked
	for y in range(data.max_size.y):
		for x in range(data.max_size.x):
			unlocked_slots[Vector2i(x, y)] = false
	
	# Unlock initial slots
	var initial_positions = data.get_initial_unlocked_positions()
	for pos in initial_positions:
		if data.is_valid_coord(pos):
			unlocked_slots[pos] = true


## Setup the grid and reader for this panel (called when panel becomes active)
func setup_grid_and_reader(parent_node: Node) -> void:
	if grid_manager != null:
		return  # Already setup
	
	# Create GridManager for this panel
	grid_manager = GridManager.new()
	grid_manager.name = "GridManager_Panel%d" % panel_index
	parent_node.add_child(grid_manager)
	
	# Apply unlocked slots to grid
	_sync_unlocked_to_grid()
	
	# Create Reader for this panel
	reader = Reader.new()
	reader.name = "Reader_Panel%d" % panel_index
	reader.grid_manager = grid_manager
	parent_node.add_child(reader)


## Synchronize unlocked slots with the grid manager
func _sync_unlocked_to_grid() -> void:
	if not grid_manager:
		return
	
	# Mark void slots for locked positions
	for coord in unlocked_slots.keys():
		var is_locked = not unlocked_slots[coord]
		var slot = grid_manager.get_slot(coord)
		if slot and is_locked:
			# Mark as void (can't place runes)
			slot.slot.data.is_void = true


## Check if a coordinate is unlocked
func is_slot_unlocked(coord: Vector2i) -> bool:
	return unlocked_slots.get(coord, false)


## Unlock a slot at the given coordinate
func unlock_slot(coord: Vector2i) -> bool:
	if not data.is_valid_coord(coord):
		return false
	
	if unlocked_slots.get(coord, false):
		return false  # Already unlocked
	
	unlocked_slots[coord] = true
	slot_unlocked.emit(coord)
	
	# Update grid if exists
	if grid_manager:
		var slot = grid_manager.get_slot(coord)
		if slot:
			slot.slot.data.is_void = false
	
	return true


## Unlock multiple slots from a slot piece
func unlock_slots_from_piece(positions: Array[Vector2i], base_coord: Vector2i) -> int:
	var unlocked_count = 0
	for offset in positions:
		var actual_coord = base_coord + offset
		if unlock_slot(actual_coord):
			unlocked_count += 1
	return unlocked_count


## Get the count of unlocked slots
func get_unlocked_slot_count() -> int:
	var count = 0
	for unlocked in unlocked_slots.values():
		if unlocked:
			count += 1
	return count


## Get the count of locked slots
func get_locked_slot_count() -> int:
	return data.get_max_slot_count() - get_unlocked_slot_count()


## Get all unlocked coordinates
func get_unlocked_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord in unlocked_slots.keys():
		if unlocked_slots[coord]:
			coords.append(coord)
	return coords


## Get all locked coordinates (potential expansion slots)
func get_locked_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord in unlocked_slots.keys():
		if not unlocked_slots[coord]:
			coords.append(coord)
	return coords


## Check if a slot piece can be placed at the given position
func can_place_piece(piece_positions: Array[Vector2i], base_coord: Vector2i) -> bool:
	# At least one slot must be adjacent to an already unlocked slot
	var has_adjacent = false
	
	for offset in piece_positions:
		var actual_coord = base_coord + offset
		
		# Must be within bounds
		if not data.is_valid_coord(actual_coord):
			return false
		
		# Must be currently locked
		if unlocked_slots.get(actual_coord, false):
			return false
		
		# Check for adjacent unlocked slots
		var neighbors = [
			actual_coord + Vector2i.UP,
			actual_coord + Vector2i.DOWN,
			actual_coord + Vector2i.LEFT,
			actual_coord + Vector2i.RIGHT
		]
		for neighbor in neighbors:
			if unlocked_slots.get(neighbor, false):
				has_adjacent = true
				break
	
	return has_adjacent


# --- Relic Management ---

## Attach a relic to this panel
func attach_relic(relic) -> bool:  # relic: RelicInstance
	if attached_relics.size() >= data.max_relics:
		return false
	
	if relic in attached_relics:
		return false
	
	attached_relics.append(relic)
	_recalculate_relic_multiplier()
	relic_attached.emit(relic)
	return true


## Detach a relic from this panel
func detach_relic(relic) -> bool:  # relic: RelicInstance
	var index = attached_relics.find(relic)
	if index == -1:
		return false
	
	attached_relics.remove_at(index)
	_recalculate_relic_multiplier()
	relic_detached.emit(relic)
	return true


## Recalculate the combined multiplier from all attached relics
func _recalculate_relic_multiplier() -> void:
	relic_multiplier = 1.0
	for relic in attached_relics:
		if relic.has_method("get_multiplier_bonus"):
			relic_multiplier += relic.get_multiplier_bonus()


## Get available relic slots
func get_available_relic_slots() -> int:
	return data.max_relics - attached_relics.size()


# --- Score Calculation ---

## Get the total panel multiplier (base + relics + upgrades)
func get_panel_multiplier() -> float:
	var base = data.base_panel_multiplier
	var upgrade_bonus = upgrade_level * 0.1  # +10% per upgrade
	return (base + upgrade_bonus) * relic_multiplier


## Calculate final panel score
func calculate_final_score() -> float:
	return current_score * get_panel_multiplier()


## Reset panel state for new battle
func reset_for_battle() -> void:
	current_score = 0
	if battle_context:
		battle_context.current_score = 0


## Full reset for game over - resets unlocked slots back to initial 3x3
func full_reset() -> void:
	reset_for_battle()
	attached_relics.clear()
	relic_multiplier = 1.0
	upgrade_level = 0
	
	# Reset unlocked slots to initial configuration
	_initialize_unlocked_slots()
	
	# Sync with grid if it exists
	if grid_manager:
		grid_manager.clear_grid()
		_sync_unlocked_to_grid()


## Start battle on this panel
func start_battle() -> void:
	if not reader or not grid_manager:
		push_error("Panel %d not properly initialized for battle" % panel_index)
		return
	
	reset_for_battle()
	battle_context = BattleContext.new(grid_manager)
	reader.start_sequence()


## Get a summary of this panel's state
func get_summary() -> Dictionary:
	return {
		"index": panel_index,
		"name": data.display_name,
		"unlocked": is_unlocked,
		"unlocked_slots": get_unlocked_slot_count(),
		"max_slots": data.get_max_slot_count(),
		"relics": attached_relics.size(),
		"max_relics": data.max_relics,
		"multiplier": get_panel_multiplier(),
		"current_score": current_score,
	}
