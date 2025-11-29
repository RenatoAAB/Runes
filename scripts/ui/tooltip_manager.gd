class_name TooltipManager
extends Control

## Simple singleton-like manager for tooltips.
## In a real project, this would be an Autoload or part of the main UI canvas.

@export var label_settings: LabelSettings

@onready var label: RichTextLabel = RichTextLabel.new()
@onready var panel: PanelContainer = PanelContainer.new()

var _force_left: bool = false
var _rune_text: String = ""
var _slot_text: String = ""

func _ready() -> void:
	# Setup simple tooltip UI
	add_child(panel)
	panel.add_child(label)
	
	# Configure RichTextLabel
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.bbcode_enabled = true
	
	if label_settings:
		_apply_label_settings()
	
	panel.hide()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style
	panel.z_index = 100 # On top

func _process(_delta: float) -> void:
	if panel.visible:
		var mouse_pos = get_global_mouse_position()
		var offset = Vector2(15, 15)
		
		if _force_left:
			# Position to the left of the mouse
			panel.global_position = mouse_pos - Vector2(panel.size.x + 15, -15)
		else:
			# Default to right
			panel.global_position = mouse_pos + offset

func show_tooltip(text: String, force_left: bool = false) -> void:
	set_rune_tooltip(text, force_left)

func set_rune_tooltip(text: String, force_left: bool = false) -> void:
	_rune_text = text
	_force_left = force_left
	_update_display()

func set_slot_tooltip(text: String) -> void:
	_slot_text = text
	_update_display()

func hide_tooltip() -> void:
	clear_rune_tooltip()

func clear_rune_tooltip() -> void:
	_rune_text = ""
	_update_display()

func clear_slot_tooltip() -> void:
	_slot_text = ""
	_update_display()

func _update_display() -> void:
	var final_text = ""
	if _rune_text != "":
		final_text = _rune_text
		
	if _slot_text != "":
		if final_text != "":
			final_text += "\n[color=gray]----------------[/color]\n" # Separator
		final_text += _slot_text
		
	if final_text == "":
		panel.hide()
	else:
		label.text = final_text
		panel.show()
		panel.size = Vector2.ZERO # Reset size to fit content

func _apply_label_settings() -> void:
	if not label_settings or not label:
		return
		
	if label_settings.font:
		label.add_theme_font_override("normal_font", label_settings.font)
	
	if label_settings.font_size > 0:
		label.add_theme_font_size_override("normal_font_size", label_settings.font_size)
		
	if label_settings.font_color != Color(1, 1, 1, 1):
		label.add_theme_color_override("default_color", label_settings.font_color)
	
	if label_settings.outline_size > 0:
		label.add_theme_constant_override("outline_size", label_settings.outline_size)
		label.add_theme_color_override("outline_color", label_settings.outline_color)
