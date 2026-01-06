class_name RelicSlotUI
extends PanelContainer

## UI component for displaying and interacting with a relic slot.
## Uses SlotInstance internally to store the relic data.
## Can be empty (for attachment) or filled (showing attached relic).

signal relic_dropped(relic: RelicInstance, slot_ui: RelicSlotUI)
signal relic_clicked(relic: RelicInstance)
signal slot_clicked(slot_ui: RelicSlotUI)

@export var slot_size: Vector2 = Vector2(60, 60)
@export var empty_color: Color = Color(0.2, 0.2, 0.25, 0.8)
@export var filled_color: Color = Color(0.3, 0.3, 0.4, 0.9)
@export var hover_color: Color = Color(0.4, 0.4, 0.5, 1.0)

## The underlying slot instance that stores the relic
var slot_instance: SlotInstance = null

## Convenience property to get/set the relic
var relic: RelicInstance:
	get:
		if slot_instance:
			return slot_instance.get_relic() as RelicInstance
		return null
	set(value):
		if slot_instance:
			if value:
				slot_instance.place_relic(value)
			else:
				slot_instance.remove_relic()
		_update_visuals()

var slot_index: int = 0
var panel_index: int = 0

var icon_rect: TextureRect
var rarity_border: ColorRect
var plus_label: Label
var highlight_rect: ColorRect
var type_indicator: Label  # Shows "R" for relic slot

var _is_hovered: bool = false
var _is_dragging: bool = false


func _ready() -> void:
	custom_minimum_size = slot_size
	_initialize_slot_instance()
	_setup_ui()
	_update_visuals()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _initialize_slot_instance() -> void:
	# Create a SlotInstance configured for relic storage
	var slot_data = SlotData.new()
	slot_data.id = "relic_slot_%d_%d" % [panel_index, slot_index]
	slot_data.slot_name = "Relic Slot"
	slot_data.base_multiplier = 1.0
	
	slot_instance = SlotInstance.new(slot_data)
	slot_instance.set_as_relic_slot()


func _setup_ui() -> void:
	# Background
	var style = StyleBoxFlat.new()
	style.bg_color = empty_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.3, 0.6, 0.5)  # Purple tint for relic slots
	add_theme_stylebox_override("panel", style)
	
	# Type indicator (small "R" in corner)
	type_indicator = Label.new()
	type_indicator.text = "R"
	type_indicator.add_theme_font_size_override("font_size", 10)
	type_indicator.add_theme_color_override("font_color", Color(0.7, 0.5, 0.8, 0.6))
	type_indicator.position = Vector2(4, 2)
	type_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(type_indicator)
	
	# Rarity border
	rarity_border = ColorRect.new()
	rarity_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	rarity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_border.color = Color.TRANSPARENT
	add_child(rarity_border)
	
	# Icon
	icon_rect = TextureRect.new()
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)
	
	# Plus label for empty slots
	plus_label = Label.new()
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus_label.add_theme_font_size_override("font_size", 24)
	plus_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	plus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plus_label)
	
	# Highlight
	highlight_rect = ColorRect.new()
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.color = Color.TRANSPARENT
	add_child(highlight_rect)


## Set the relic for this slot (via SlotInstance)
func set_relic(p_relic: RelicInstance) -> void:
	if not slot_instance:
		_initialize_slot_instance()
	
	slot_instance.remove_relic()  # Clear existing
	if p_relic:
		slot_instance.place_relic(p_relic)
	_update_visuals()


## Clear the relic from this slot
func clear_relic() -> void:
	if slot_instance:
		slot_instance.remove_relic()
	_update_visuals()


## Check if slot is empty
func is_empty() -> bool:
	return not slot_instance or not slot_instance.has_relic()


## Get the SlotInstance for external use
func get_slot_instance() -> SlotInstance:
	return slot_instance


func _update_visuals() -> void:
	var current_relic = relic
	
	if current_relic:
		# Show relic
		plus_label.visible = false
		if current_relic.data.icon:
			icon_rect.texture = current_relic.data.icon
			icon_rect.visible = true
		else:
			# Show placeholder for relic without icon
			icon_rect.visible = false
		
		# Update background
		var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.bg_color = filled_color
			add_theme_stylebox_override("panel", style)
		
		# Show rarity border
		rarity_border.color = _get_rarity_color(current_relic.data.rarity)
	else:
		# Show empty slot
		plus_label.visible = true
		icon_rect.visible = false
		
		var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if style:
			style.bg_color = empty_color
			add_theme_stylebox_override("panel", style)
		
		rarity_border.color = Color.TRANSPARENT


func _get_rarity_color(rarity_value: GameEnums.Rarity) -> Color:
	match rarity_value:
		GameEnums.Rarity.COMMON:
			return Color(0.6, 0.6, 0.6, 0.3)
		GameEnums.Rarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2, 0.3)
		GameEnums.Rarity.RARE:
			return Color(0.2, 0.4, 0.9, 0.3)
		GameEnums.Rarity.EPIC:
			return Color(0.7, 0.3, 0.9, 0.3)
		GameEnums.Rarity.LEGENDARY:
			return Color(1.0, 0.7, 0.2, 0.3)
		_:
			return Color.TRANSPARENT


func _on_mouse_entered() -> void:
	_is_hovered = true
	highlight_rect.color = Color(1, 1, 1, 0.1)
	
	if relic:
		_show_tooltip()


func _on_mouse_exited() -> void:
	_is_hovered = false
	highlight_rect.color = Color.TRANSPARENT
	_hide_tooltip()


func _show_tooltip() -> void:
	var current_relic = relic
	if not current_relic:
		return
	
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("show_tooltip"):
		var info = current_relic.get_display_info()
		var text = "[b]%s[/b]\n%s" % [info.name, info.description]
		tooltip_manager.show_tooltip(text, self)


func _hide_tooltip() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
		tooltip_manager.hide_tooltip()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var current_relic = relic
			if current_relic:
				relic_clicked.emit(current_relic)
			else:
				slot_clicked.emit(self)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Can drop if this slot is empty and data is a relic
	if not is_empty():
		return false
	
	if data is Dictionary and data.has("type") and data.type == "relic":
		return true
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("relic"):
		var dropped_relic = data.relic as RelicInstance
		relic_dropped.emit(dropped_relic, self)
