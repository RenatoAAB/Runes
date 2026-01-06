class_name PiecePreviewUI
extends Control

## UI component for previewing slot piece placement on a panel.
## Shows where a piece will be placed and highlights valid/invalid positions.

signal placement_confirmed(piece: SlotPieceInstance, coord: Vector2i)
signal placement_cancelled

@export var slot_size: float = 50.0
@export var valid_color: Color = Color(0.2, 0.8, 0.2, 0.5)
@export var invalid_color: Color = Color(0.8, 0.2, 0.2, 0.5)
@export var neutral_color: Color = Color(0.5, 0.5, 0.5, 0.3)

var piece: SlotPieceInstance = null
var panel: PanelInstance = null
var current_coord: Vector2i = Vector2i.ZERO
var is_valid_placement: bool = false

var _preview_rects: Array[ColorRect] = []
var _is_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Start preview mode with a piece
func start_preview(p_piece: SlotPieceInstance, p_panel: PanelInstance) -> void:
	piece = p_piece
	panel = p_panel
	_is_active = true
	visible = true
	_create_preview_rects()
	_update_preview_position(Vector2i.ZERO)


## Stop preview mode
func stop_preview() -> void:
	_is_active = false
	visible = false
	piece = null
	panel = null
	_clear_preview_rects()


## Update preview position based on mouse/coord
func update_position(coord: Vector2i) -> void:
	if not _is_active:
		return
	_update_preview_position(coord)


## Rotate the preview piece
func rotate_preview() -> void:
	if piece:
		piece.rotate_clockwise()
		_create_preview_rects()
		_update_preview_position(current_coord)


## Confirm placement at current position
func confirm_placement() -> void:
	if _is_active and is_valid_placement and piece:
		placement_confirmed.emit(piece, current_coord)
		stop_preview()


## Cancel placement
func cancel_placement() -> void:
	placement_cancelled.emit()
	stop_preview()


func _create_preview_rects() -> void:
	_clear_preview_rects()
	
	if not piece:
		return
	
	var shape = piece.get_current_shape()
	for pos in shape:
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(slot_size, slot_size)
		rect.size = Vector2(slot_size, slot_size)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.color = neutral_color
		add_child(rect)
		_preview_rects.append(rect)


func _clear_preview_rects() -> void:
	for rect in _preview_rects:
		rect.queue_free()
	_preview_rects.clear()


func _update_preview_position(coord: Vector2i) -> void:
	current_coord = coord
	
	if not piece or not panel:
		is_valid_placement = false
		return
	
	var shape = piece.get_current_shape()
	is_valid_placement = panel.can_place_piece(shape, coord)
	
	# Update rect positions and colors
	for i in range(mini(shape.size(), _preview_rects.size())):
		var pos = shape[i]
		var actual_coord = coord + pos
		var rect = _preview_rects[i]
		
		# Position the rect
		rect.position = Vector2(actual_coord.x * slot_size, actual_coord.y * slot_size)
		
		# Color based on validity
		if panel.data.is_valid_coord(actual_coord):
			if panel.is_slot_unlocked(actual_coord):
				# Already unlocked - can't place here
				rect.color = invalid_color
			else:
				# Valid placement position
				rect.color = valid_color if is_valid_placement else neutral_color
		else:
			# Out of bounds
			rect.color = invalid_color


func _input(event: InputEvent) -> void:
	if not _is_active:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			rotate_preview()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			cancel_placement()
			get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_valid_placement:
			confirm_placement()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()
			get_viewport().set_input_as_handled()
