class_name SlotPieceInstance
extends RefCounted

## Runtime instance of a Slot Piece.
## Used when the player acquires a piece before placing it on a panel.

var data: SlotPieceData

## Current rotation (0-3, each representing 90 degree rotation)
var current_rotation: int = 0

## Has this piece been placed?
var is_placed: bool = false

## Panel it was placed on (if placed)
var placed_on_panel_index: int = -1

## Base coordinate where it was placed (if placed)
var placed_at_coord: Vector2i = Vector2i.ZERO


func _init(p_data: SlotPieceData):
	data = p_data


## Get the current shape with rotation applied
func get_current_shape() -> Array[Vector2i]:
	return data.get_rotated_shape(current_rotation)


## Rotate the piece clockwise
func rotate_clockwise() -> void:
	current_rotation = (current_rotation + 1) % 4


## Rotate the piece counter-clockwise
func rotate_counter_clockwise() -> void:
	current_rotation = (current_rotation + 3) % 4


## Get actual grid positions if placed at a specific coordinate
func get_positions_at(base_coord: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for offset in get_current_shape():
		positions.append(base_coord + offset)
	return positions


## Mark as placed on a panel
func place_on_panel(panel_index: int, coord: Vector2i) -> void:
	is_placed = true
	placed_on_panel_index = panel_index
	placed_at_coord = coord


## Get the slot type for a specific position index
func get_slot_type_at(index: int) -> SlotData:
	return data.get_slot_type_at(index)


## Get display info
func get_display_info() -> Dictionary:
	var modifier_names: Array[String] = []
	if data.slot_modifiers:
		for mod in data.slot_modifiers:
			if mod and mod is SlotModifierData:
				modifier_names.append(mod.display_name)
	
	return {
		"name": data.display_name,
		"description": data.description,
		"size": data.get_slot_count(),
		"slot_count": data.get_slot_count(),
		"rarity": data.rarity,
		"rotation": current_rotation,
		"is_placed": is_placed,
		"modifiers": modifier_names
	}


## Get the shape (considering current rotation)
func get_shape() -> Array[Vector2i]:
	return get_current_shape()
