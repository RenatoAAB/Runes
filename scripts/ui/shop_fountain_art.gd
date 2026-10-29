extends Node2D
## Approved static fountain composition. Gameplay stays in ShopUI/ShopManager.
const PANEL_HOVER := preload("res://scripts/ui/shop_panel_hover.gd")
const BUTTON_NAMES := {"neutral":"Repeat", "water":"Water", "fire":"Fire", "earth":"Earth", "air":"Air", "soul":"Spirit"}
var panel_hovers: Dictionary = {}

func _ready() -> void:
	call_deferred("_bind_controls")

func _bind_controls() -> void:
	var controls: Control = get_parent().get_node("ElementPedestals")
	controls.position = Vector2.ZERO
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sprite: Sprite2D in $Panels.get_children():
		var id := String(sprite.name)
		var button: Button = controls.get_node(BUTTON_NAMES[id])
		button.position = sprite.position
		button.size = sprite.texture.get_size()
		button.text = ""
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var hover := PANEL_HOVER.new()
		hover.name = id + "PanelHover"
		add_child(hover)
		hover.setup(sprite,button,id)
		panel_hovers[id] = hover

