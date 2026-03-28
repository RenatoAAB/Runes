class_name SlotPiecePreviewGrid
extends Control

## Draws a slot piece's polyomino shape using mini-slot styled cells.
## Used in shop, inventory, and tooltips to give visual representation of the piece.

const DEFAULT_CELL_SIZE: int = 14
const DEFAULT_CELL_GAP: int = 2

## Colors
const COLOR_SLOT_BG := Color(0.22, 0.22, 0.28, 1.0)
const COLOR_SLOT_BORDER := Color(0.5, 0.5, 0.6, 1.0)
const COLOR_MODIFIER_BORDER := Color(0.7, 0.7, 0.8, 1.0)

var _cells: Array[Control] = []
var _cell_size: int = DEFAULT_CELL_SIZE
var _cell_gap: int = DEFAULT_CELL_GAP


func setup(piece_data: SlotPieceData, cell_size: int = DEFAULT_CELL_SIZE, cell_gap: int = DEFAULT_CELL_GAP) -> void:
	_cell_size = cell_size
	_cell_gap = cell_gap
	_rebuild(piece_data)


func setup_from_instance(piece: SlotPieceInstance, cell_size: int = DEFAULT_CELL_SIZE, cell_gap: int = DEFAULT_CELL_GAP) -> void:
	_cell_size = cell_size
	_cell_gap = cell_gap
	_rebuild_from_instance(piece)


## Auto-fit the piece into a given available area (e.g., the parent item's size).
## Calculates the best cell_size so the shape fills the space well.
func setup_auto_fit(piece_data: SlotPieceData, available: Vector2, gap: int = 2) -> void:
	_cell_gap = gap
	if not piece_data or piece_data.shape.is_empty():
		return

	var bounds := piece_data.get_bounds()
	var cols: int = bounds.size.x
	var rows: int = bounds.size.y

	# Calculate max cell size that fits both axes
	var max_w: int = int((available.x - gap * maxi(cols - 1, 0)) / maxi(cols, 1))
	var max_h: int = int((available.y - gap * maxi(rows - 1, 0)) / maxi(rows, 1))
	_cell_size = maxi(4, mini(max_w, max_h))

	_rebuild(piece_data)


## Auto-fit from instance (considers rotation)
func setup_auto_fit_instance(piece: SlotPieceInstance, available: Vector2, gap: int = 2) -> void:
	_cell_gap = gap
	if not piece or not piece.data:
		return

	var shape := piece.get_current_shape()
	if shape.is_empty():
		return

	var min_pos := Vector2i(999, 999)
	var max_pos := Vector2i(-999, -999)
	for pos in shape:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)

	var cols: int = max_pos.x - min_pos.x + 1
	var rows: int = max_pos.y - min_pos.y + 1

	var max_w: int = int((available.x - _cell_gap * maxi(cols - 1, 0)) / maxi(cols, 1))
	var max_h: int = int((available.y - _cell_gap * maxi(rows - 1, 0)) / maxi(rows, 1))
	_cell_size = maxi(4, mini(max_w, max_h))

	_rebuild_from_instance(piece)


func clear() -> void:
	for c in _cells:
		c.queue_free()
	_cells.clear()


func _rebuild(piece_data: SlotPieceData) -> void:
	clear()
	if not piece_data or piece_data.shape.is_empty():
		return

	var shape = piece_data.shape
	var modifiers = piece_data.slot_modifiers

	_build_cells(shape, modifiers)


func _rebuild_from_instance(piece: SlotPieceInstance) -> void:
	clear()
	if not piece or not piece.data:
		return

	var shape = piece.get_current_shape()
	var modifiers = piece.data.slot_modifiers

	_build_cells(shape, modifiers)


func _build_cells(shape: Array[Vector2i], modifiers: Array) -> void:
	# Normalize shape to origin
	var min_pos := Vector2i(999, 999)
	var max_pos := Vector2i(-999, -999)
	for pos in shape:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)

	var shape_size := max_pos - min_pos + Vector2i.ONE
	var total_w := shape_size.x * (_cell_size + _cell_gap) - _cell_gap
	var total_h := shape_size.y * (_cell_size + _cell_gap) - _cell_gap

	custom_minimum_size = Vector2(total_w, total_h)

	for i in range(shape.size()):
		var pos := shape[i] - min_pos
		var cell := _create_slot_cell(i, modifiers)
		cell.position = Vector2(
			pos.x * (_cell_size + _cell_gap),
			pos.y * (_cell_size + _cell_gap)
		)
		add_child(cell)
		_cells.append(cell)


func _create_slot_cell(index: int, modifiers: Array) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(_cell_size, _cell_size)
	cell.size = Vector2(_cell_size, _cell_size)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(2)
	style.set_border_width_all(1)

	# Determine color from modifier
	var has_modifier := index < modifiers.size() and modifiers[index] != null
	if has_modifier:
		var mod_color := SlotPieceUI.get_color_for_modifier_type(modifiers[index].modifier_type)
		style.bg_color = mod_color.darkened(0.5)
		style.border_color = mod_color
	else:
		style.bg_color = COLOR_SLOT_BG
		style.border_color = COLOR_SLOT_BORDER

	cell.add_theme_stylebox_override("panel", style)
	return cell
