class_name TooltipManager
extends Control

## Simple singleton-like manager for tooltips.
## In a real project, this would be an Autoload or part of the main UI canvas.

@onready var label: Label = Label.new()
@onready var panel: PanelContainer = PanelContainer.new()

func _ready() -> void:
	# Setup simple tooltip UI
	add_child(panel)
	panel.add_child(label)
	panel.hide()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style
	panel.z_index = 100 # On top

func _process(_delta: float) -> void:
	if panel.visible:
		panel.global_position = get_global_mouse_position() + Vector2(15, 15)

func show_tooltip(text: String) -> void:
	label.text = text
	panel.show()
	panel.size = Vector2.ZERO # Reset size to fit content

func hide_tooltip() -> void:
	panel.hide()
