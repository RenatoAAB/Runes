class_name GridManager
extends Node

## Manages the 5x5 Grid of GridSlots.
## Handles placement, movement, and coordinate queries.

const GRID_SIZE = 5

# 1D Array representing 5x5 grid. Index = y * WIDTH + x
var grid: Array[GridSlot] = []

signal slot_changed(coord: Vector2i)

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	grid.clear()
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			grid.append(GridSlot.new(Vector2i(x, y)))

# --- Core Accessors ---

func get_slot(coord: Vector2i) -> GridSlot:
	if not is_valid_coord(coord):
		return null
	var index = coord.y * GRID_SIZE + coord.x
	return grid[index]

func is_valid_coord(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < GRID_SIZE and coord.y >= 0 and coord.y < GRID_SIZE

# --- Matrix Operations ---

func get_neighbors(coord: Vector2i, include_diagonals: bool = false) -> Array[GridSlot]:
	var neighbors: Array[GridSlot] = []
	var directions = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
	]
	
	if include_diagonals:
		directions.append_array([
			Vector2i(-1, -1), Vector2i(1, -1), 
			Vector2i(-1, 1), Vector2i(1, 1)
		])
		
	for dir in directions:
		var neighbor_coord = coord + dir
		if is_valid_coord(neighbor_coord):
			neighbors.append(get_slot(neighbor_coord))
			
	return neighbors

func get_row(y: int) -> Array[GridSlot]:
	var row: Array[GridSlot] = []
	if y < 0 or y >= GRID_SIZE:
		return row
	
	for x in range(GRID_SIZE):
		row.append(get_slot(Vector2i(x, y)))
	return row

func get_column(x: int) -> Array[GridSlot]:
	var col: Array[GridSlot] = []
	if x < 0 or x >= GRID_SIZE:
		return col
		
	for y in range(GRID_SIZE):
		col.append(get_slot(Vector2i(x, y)))
	return col

# --- Manipulation ---

func place_rune(rune_data: RuneData, coord: Vector2i) -> bool:
	var slot = get_slot(coord)
	if slot and slot.is_empty():
		var instance = RuneInstance.new(rune_data)
		slot.set_rune(instance)
		slot_changed.emit(coord)
		return true
	return false

func move_rune(from_coord: Vector2i, to_coord: Vector2i) -> bool:
	var from_slot = get_slot(from_coord)
	var to_slot = get_slot(to_coord)
	
	if not from_slot or not to_slot:
		return false
		
	# If moving to same slot, do nothing
	if from_coord == to_coord:
		return true
		
	if from_slot.is_empty():
		return false
		
	# Swap logic
	# Use remove_rune() to ensure buffs are stripped from the leaving runes
	var rune_a = from_slot.remove_rune()
	var rune_b = to_slot.remove_rune()
	
	# Use set_rune() to ensure buffs are applied from the entering slots
	from_slot.set_rune(rune_b)
	to_slot.set_rune(rune_a)
	
	slot_changed.emit(from_coord)
	slot_changed.emit(to_coord)
	
	return true

func rotate_runes(slots: Array[GridSlot], clockwise: bool) -> void:
	if slots.size() < 2:
		return
		
	var runes: Array[RuneInstance] = []
	for slot in slots:
		# Remove rune to strip buffs
		runes.append(slot.remove_rune()) 
		
	# Shift array
	if clockwise:
		var last = runes.pop_back()
		runes.push_front(last)
	else:
		var first = runes.pop_front()
		runes.push_back(first)
		
	# Reassign
	for i in range(slots.size()):
		slots[i].set_rune(runes[i])
		slot_changed.emit(slots[i].grid_position)

func process_round_end() -> void:
	for slot in grid:
		slot.process_states()
		if slot.rune:
			slot.rune.reset_state()
			# Re-apply slot buffs because reset_state cleared them
			slot.apply_buffs(slot.rune)

func clear_grid() -> void:
	for slot in grid:
		if not slot.is_empty():
			slot.remove_rune()
			slot_changed.emit(slot.grid_position)
