class_name SlotPieceUI
extends PanelContainer

## Visual representation of a SlotPiece (polyomino).
## Shows the shape of the piece with colored cells representing modifiers.
## Used in inventory, shop, and during drag preview.

signal piece_clicked(piece: SlotPieceInstance)
signal piece_drag_started(piece: SlotPieceInstance)

const CELL_SIZE: int = 16  # Size of each cell in the polyomino display
const CELL_GAP: int = 2    # Gap between cells

## Colors for different modifier types
const MODIFIER_COLORS = {
	"multiplier": Color(1.0, 0.8, 0.2, 1.0),      # Gold - multiplier bonus
	"trigger": Color(0.2, 0.8, 1.0, 1.0),         # Cyan - trigger bonus
	"economy": Color(0.2, 1.0, 0.4, 1.0),         # Green - money bonus
	"preservation": Color(0.8, 0.4, 1.0, 1.0),    # Purple - preservation
	"protection": Color(0.4, 0.6, 1.0, 1.0),      # Blue - protection
	"state": Color(1.0, 0.4, 0.4, 1.0),           # Red - state effects
	"default": Color(0.6, 0.6, 0.6, 1.0),         # Gray - no modifier
}

var piece: SlotPieceInstance = null
var slot_index: int = -1

var _cells_container: Control
var _cells: Array[ColorRect] = []
var _is_hovered: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	_setup_ui()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _setup_ui() -> void:
	# Background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	add_theme_stylebox_override("panel", style)
	
	# Container for cells
	_cells_container = Control.new()
	_cells_container.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_cells_container)


## Set the piece to display
func set_piece(p_piece: SlotPieceInstance) -> void:
	piece = p_piece
	_update_visuals()


## Clear the piece
func clear_piece() -> void:
	piece = null
	_update_visuals()


func _update_visuals() -> void:
	# Clear existing cells
	for cell in _cells:
		cell.queue_free()
	_cells.clear()
	
	if not piece or not piece.data:
		return
	
	# Calculate bounding box
	var shape = piece.get_shape()
	if shape.is_empty():
		return
	
	var min_pos = Vector2i(999, 999)
	var max_pos = Vector2i(-999, -999)
	for pos in shape:
		min_pos.x = mini(min_pos.x, pos.x)
		min_pos.y = mini(min_pos.y, pos.y)
		max_pos.x = maxi(max_pos.x, pos.x)
		max_pos.y = maxi(max_pos.y, pos.y)
	
	var shape_size = max_pos - min_pos + Vector2i.ONE
	var total_width = shape_size.x * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var total_height = shape_size.y * (CELL_SIZE + CELL_GAP) - CELL_GAP
	
	# Update minimum size based on piece shape
	custom_minimum_size = Vector2(
		maxf(48, total_width + 16),
		maxf(48, total_height + 16)
	)
	
	# Center the cells container
	_cells_container.position = Vector2(
		(custom_minimum_size.x - total_width) / 2,
		(custom_minimum_size.y - total_height) / 2
	)
	
	# Create visual cells
	var slot_types = piece.data.slot_types
	var modifiers = piece.data.slot_modifiers
	
	for i in range(shape.size()):
		var pos = shape[i] - min_pos
		
		var cell = ColorRect.new()
		cell.size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.position = Vector2(
			pos.x * (CELL_SIZE + CELL_GAP),
			pos.y * (CELL_SIZE + CELL_GAP)
		)
		
		# Determine cell color based on modifier
		var modifier_type = "default"
		if i < modifiers.size() and modifiers[i]:
			modifier_type = _get_modifier_type(modifiers[i])
		
		cell.color = MODIFIER_COLORS.get(modifier_type, MODIFIER_COLORS.default)
		
		# Add border effect
		var border = ReferenceRect.new()
		border.size = cell.size
		border.border_color = cell.color.darkened(0.3)
		border.border_width = 1.5
		border.editor_only = false
		cell.add_child(border)
		
		_cells_container.add_child(cell)
		_cells.append(cell)


## Get modifier type string for color lookup
static func _get_modifier_type(modifier: SlotModifierData) -> String:
	match modifier.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			return "multiplier"
		SlotModifierData.ModifierType.TRIGGER:
			return "trigger"
		SlotModifierData.ModifierType.ECONOMY:
			return "economy"
		SlotModifierData.ModifierType.PRESERVATION:
			return "preservation"
		SlotModifierData.ModifierType.PROTECTION:
			return "protection"
		SlotModifierData.ModifierType.STATE:
			return "state"
		_:
			return "default"


## Get color for a modifier type enum value
static func get_color_for_modifier_type(modifier_type: SlotModifierData.ModifierType) -> Color:
	var type_key: String
	match modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			type_key = "multiplier"
		SlotModifierData.ModifierType.TRIGGER:
			type_key = "trigger"
		SlotModifierData.ModifierType.ECONOMY:
			type_key = "economy"
		SlotModifierData.ModifierType.PRESERVATION:
			type_key = "preservation"
		SlotModifierData.ModifierType.PROTECTION:
			type_key = "protection"
		SlotModifierData.ModifierType.STATE:
			type_key = "state"
		_:
			type_key = "default"
	return MODIFIER_COLORS.get(type_key, MODIFIER_COLORS.default)


func _on_mouse_entered() -> void:
	_is_hovered = true
	modulate = Color(1.2, 1.2, 1.2)
	
	if piece:
		_show_tooltip()


func _on_mouse_exited() -> void:
	_is_hovered = false
	modulate = Color.WHITE
	_hide_tooltip()


func _show_tooltip() -> void:
	if not piece:
		return
	
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var info = piece.get_display_info()
		var text = "[b]%s[/b]\nSize: %d slots\nRotation: %d°" % [
			info.name, info.size, info.rotation * 90
		]
		if info.has("modifiers") and not info.modifiers.is_empty():
			text += "\n[color=yellow]Modifiers:[/color]"
			for mod_name in info.modifiers:
				text += "\n  • " + mod_name
		tooltip_manager.show_tooltip(text, self)


func _hide_tooltip() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
		tooltip_manager.hide_tooltip()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and piece:
			piece_clicked.emit(piece)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not piece:
		return null
	
	piece_drag_started.emit(piece)
	
	# Create drag preview showing the full piece shape
	var preview = SlotPieceUI.new()
	preview.set_piece(piece)
	preview.modulate = Color(1, 1, 1, 0.8)
	set_drag_preview(preview)
	
	return {
		"type": "slot_piece",
		"piece": piece,
		"source_ui": self,
		"slot_index": slot_index
	}
