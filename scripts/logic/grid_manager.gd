class_name GridManager
extends Node

## Manages the 5x5 Grid of GridSlots.
## Handles placement, movement, and coordinate queries.

const GRID_SIZE = 5

# 1D Array representing 5x5 grid. Index = y * WIDTH + x
var grid: Array[GridSlot] = []

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
	var rune_a = from_slot.rune
	var rune_b = to_slot.rune
	
	from_slot.set_rune(rune_b)
	to_slot.set_rune(rune_a)
	
	return true

func process_round_end() -> void:
	for slot in grid:
		slot.process_states()
		if slot.rune:
			slot.rune.reset_state()
