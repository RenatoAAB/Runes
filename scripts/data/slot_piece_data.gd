class_name SlotPieceData
extends Resource

## Defines a Slot Piece - an agglomeration of 1-4 slots in adjacent positions.
## Slot pieces are used to expand panels by adding new slots.
## They work like Tetris pieces (polyominoes) with orthogonal connections only.

@export_group("Identity")
@export var id: String
@export var display_name: String
@export_multiline var description: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON

@export_group("Shape")
## Relative positions of slots in this piece. First position is always (0,0).
## All positions must be orthogonally connected.
@export var shape: Array[Vector2i] = [Vector2i.ZERO]

@export_group("Slots")
## Slot type for each position in the shape.
## If empty or smaller than shape, default slots are used.
@export var slot_types: Array[SlotData] = []

@export_group("Modifiers")
## Pre-applied modifiers to slots in this piece
## Index corresponds to shape index
@export var slot_modifiers: Array = []  # Array[SlotModifierData] when that exists

@export_group("Visuals")
@export var icon: Texture2D
@export var color_hint: Color = Color.WHITE

## Economy values are defined in ShopConfig based on rarity


## Get the number of slots in this piece
func get_slot_count() -> int:
	return shape.size()


## Get the slot type at a given shape index
func get_slot_type_at(index: int) -> SlotData:
	if index >= 0 and index < slot_types.size():
		return slot_types[index]
	return null  # Will use default


## Validate that all positions are orthogonally connected
func is_valid_shape() -> bool:
	if shape.is_empty():
		return false
	
	if shape.size() == 1:
		return true  # Single slot is always valid
	
	# Check that all positions are reachable from the first position
	var visited: Dictionary = {}
	var to_visit: Array[Vector2i] = [shape[0]]
	visited[shape[0]] = true
	
	while not to_visit.is_empty():
		var current = to_visit.pop_front()
		
		# Check orthogonal neighbors
		var neighbors = [
			current + Vector2i.UP,
			current + Vector2i.DOWN,
			current + Vector2i.LEFT,
			current + Vector2i.RIGHT
		]
		
		for neighbor in neighbors:
			if neighbor in shape and not visited.has(neighbor):
				visited[neighbor] = true
				to_visit.append(neighbor)
	
	# All positions should be visited
	return visited.size() == shape.size()


## Get the bounding box of the shape
func get_bounds() -> Rect2i:
	if shape.is_empty():
		return Rect2i()
	
	var min_pos = shape[0]
	var max_pos = shape[0]
	
	for pos in shape:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)
	
	return Rect2i(min_pos, max_pos - min_pos + Vector2i.ONE)


## Rotate the shape 90 degrees clockwise
func get_rotated_shape(times: int = 1) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = shape.duplicate()
	
	for _i in range(times % 4):
		var new_rotated: Array[Vector2i] = []
		for pos in rotated:
			# 90 degree clockwise rotation: (x, y) -> (y, -x)
			new_rotated.append(Vector2i(pos.y, -pos.x))
		rotated = new_rotated
	
	# Normalize to have minimum at origin
	return _normalize_shape(rotated)


## Normalize shape so minimum position is at origin
static func _normalize_shape(positions: Array[Vector2i]) -> Array[Vector2i]:
	if positions.is_empty():
		return positions
	
	var min_pos = positions[0]
	for pos in positions:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
	
	var normalized: Array[Vector2i] = []
	for pos in positions:
		normalized.append(pos - min_pos)
	
	return normalized


## Get all unique rotations of this shape
func get_all_rotations() -> Array[Array]:
	var rotations: Array[Array] = []
	var seen: Array[String] = []
	
	for i in range(4):
		var rotated = get_rotated_shape(i)
		var key = _shape_to_string(rotated)
		if key not in seen:
			seen.append(key)
			rotations.append(rotated)
	
	return rotations


## Convert shape to string for comparison
static func _shape_to_string(positions: Array[Vector2i]) -> String:
	var sorted_positions = positions.duplicate()
	sorted_positions.sort_custom(func(a, b): 
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	
	var parts: Array[String] = []
	for pos in sorted_positions:
		parts.append("%d,%d" % [pos.x, pos.y])
	return ";".join(parts)
