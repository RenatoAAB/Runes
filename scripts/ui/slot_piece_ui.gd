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
var _preview_grid: SlotPiecePreviewGrid = null
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
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)
	
	# Center container for the preview grid
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	
	_preview_grid = SlotPiecePreviewGrid.new()
	_preview_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_preview_grid)


## Set the piece to display
func set_piece(p_piece: SlotPieceInstance) -> void:
	piece = p_piece
	_update_visuals()


## Clear the piece
func clear_piece() -> void:
	piece = null
	_update_visuals()


func _update_visuals() -> void:
	if not _preview_grid:
		return
	
	if not piece or not piece.data:
		_preview_grid.clear()
		return
	
	# Auto-fit to fill the available area (min_size minus padding)
	var fit_area := custom_minimum_size - Vector2(16, 16)
	_preview_grid.setup_auto_fit_instance(piece, fit_area, 2)


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
