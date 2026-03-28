class_name ItemUI
extends TextureRect

## Visual representation of an ExtraInventory item (relic, modifier, piece).
## Handles Drag & Drop similar to RuneUI.
## Can display relics, modifiers, and slot pieces with appropriate visuals.

signal item_clicked(item_ui: ItemUI)
signal item_drag_started(item_ui: ItemUI)

enum ItemType { NONE, RELIC, MODIFIER, PIECE }

const SlotPiecePreviewGridScript = preload("res://scripts/ui/slot_piece_preview_grid.gd")

var item_type: ItemType = ItemType.NONE
var item_data: Variant = null  # RelicData, SlotModifierData, or SlotPieceData
var item_instance: Variant = null  # RelicInstance, null for modifiers, SlotPieceInstance

var _background: ColorRect
var _label: Label
var _piece_preview_grid: Control = null
var _is_dragging: bool = false


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_setup_visuals()
	_connect_event_bus()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _setup_visuals() -> void:
	# Background color rect
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.color = Color(0.3, 0.3, 0.3, 0.8)
	add_child(_background)
	move_child(_background, 0)
	
	# Label for item abbreviation
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


## Set a relic to display
func set_relic(relic_instance: RelicInstance) -> void:
	if not relic_instance or not relic_instance.data:
		clear()
		return
	
	item_type = ItemType.RELIC
	item_data = relic_instance.data
	item_instance = relic_instance
	
	_update_visuals()


## Set a relic from data (creates no instance)
func set_relic_data(relic_data: RelicData) -> void:
	if not relic_data:
		clear()
		return
	
	item_type = ItemType.RELIC
	item_data = relic_data
	item_instance = null
	
	_update_visuals()


## Set a modifier to display
func set_modifier(modifier_data: SlotModifierData) -> void:
	if not modifier_data:
		clear()
		return
	
	item_type = ItemType.MODIFIER
	item_data = modifier_data
	item_instance = null  # Modifiers don't have instances
	
	_update_visuals()


## Set a slot piece to display
func set_piece(piece_instance: SlotPieceInstance) -> void:
	if not piece_instance or not piece_instance.data:
		clear()
		return
	
	item_type = ItemType.PIECE
	item_data = piece_instance.data
	item_instance = piece_instance
	
	_update_visuals()


## Set a piece from data (creates no instance)
func set_piece_data(piece_data: SlotPieceData) -> void:
	if not piece_data:
		clear()
		return
	
	item_type = ItemType.PIECE
	item_data = piece_data
	item_instance = null
	
	_update_visuals()


## Clear the item display
func clear() -> void:
	item_type = ItemType.NONE
	item_data = null
	item_instance = null
	texture = null
	
	if _background:
		_background.color = Color(0.2, 0.2, 0.2, 0.5)
	if _label:
		_label.text = ""
	if _piece_preview_grid:
		_piece_preview_grid.call("clear")
		_piece_preview_grid.get_parent().visible = false


func _update_visuals() -> void:
	if not item_data:
		clear()
		return
	
	var color: Color
	var label_text: String
	var icon: Texture2D = null
	
	match item_type:
		ItemType.RELIC:
			var relic = item_data as RelicData
			color = Color.PURPLE.lightened(0.2)
			label_text = relic.display_name.substr(0, 2) if relic.display_name else "R"
			icon = relic.icon
		
		ItemType.MODIFIER:
			var modifier = item_data as SlotModifierData
			color = SlotPieceUI.get_color_for_modifier_type(modifier.modifier_type)
			label_text = modifier.display_name.substr(0, 2) if modifier.display_name else "M"
			icon = modifier.icon
		
		ItemType.PIECE:
			var _piece = item_data as SlotPieceData
			color = Color(0.2, 0.2, 0.25)
			label_text = ""
			icon = null  # Use preview grid instead
		
		_:
			color = Color.GRAY
			label_text = "?"
	
	# Apply visuals
	if _background:
		_background.color = color
	
	if _label:
		if icon:
			_label.text = ""  # Hide text if we have an icon
		else:
			_label.text = label_text
	
	texture = icon
	
	# Handle piece preview grid
	if item_type == ItemType.PIECE:
		if not _piece_preview_grid:
			# Wrap in CenterContainer to properly center the grid
			var center = CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(center)
			var grid = SlotPiecePreviewGridScript.new()
			grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
			center.add_child(grid)
			_piece_preview_grid = grid
		var piece_data = item_data as SlotPieceData
		# Use actual size when available, fallback to parent's min size or 36x36
		var available := size if size.x > 0 and size.y > 0 else Vector2(36, 36)
		var fit_area := available - Vector2(8, 8)
		if item_instance:
			_piece_preview_grid.call("setup_auto_fit_instance", item_instance as SlotPieceInstance, fit_area, 2)
		else:
			_piece_preview_grid.call("setup_auto_fit", piece_data, fit_area, 2)
		_piece_preview_grid.get_parent().visible = true
	else:
		if _piece_preview_grid:
			_piece_preview_grid.get_parent().visible = false


func _connect_event_bus() -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("relic_activated"):
		if not event_bus.relic_activated.is_connected(_on_relic_activated):
			event_bus.relic_activated.connect(_on_relic_activated)


func _on_relic_activated(event: RelicActivatedEvent) -> void:
	if item_type != ItemType.RELIC or not item_data:
		return
	if StringName(item_data.id) != event.relic_id:
		return
	_flash_relic(event.multiplier_value)


func _flash_relic(multiplier: float) -> void:
	if not _background:
		return
	var highlight = Color(1.0, 0.9, 0.4, 0.9)
	var base = _background.color
	var tween = create_tween()
	tween.tween_property(_background, "color", highlight, 0.12)
	tween.tween_property(_background, "color", base, 0.25)

	# Show multiplier value as floating text
	if _label:
		var old_text = _label.text
		var old_modulate = _label.modulate
		_label.text = "×%.2f" % multiplier
		_label.modulate = Color(1, 1, 1, 1)
		_label.show()
		var text_tween = create_tween()
		text_tween.tween_interval(0.3)
		text_tween.tween_property(_label, "modulate", Color(1, 1, 1, 0.0), 0.5)
		text_tween.finished.connect(func():
			_label.modulate = old_modulate
			_label.text = old_text
			if texture:
				_label.text = ""  # restore hidden state if icon is present
		)


## Get display name for tooltip
func get_display_name() -> String:
	if not item_data:
		return ""
	
	match item_type:
		ItemType.RELIC:
			return (item_data as RelicData).display_name
		ItemType.MODIFIER:
			return (item_data as SlotModifierData).display_name
		ItemType.PIECE:
			return (item_data as SlotPieceData).display_name
	
	return ""


## Get item type as string
func get_item_type_string() -> String:
	match item_type:
		ItemType.RELIC:
			return "relic"
		ItemType.MODIFIER:
			return "modifier"
		ItemType.PIECE:
			return "piece"
	return ""


func _on_mouse_entered() -> void:
	modulate = Color(1.2, 1.2, 1.2)
	_show_tooltip()


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
	_hide_tooltip()


func _show_tooltip() -> void:
	if not item_data:
		return
	
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("show_item_tooltip"):
		tooltip_manager.show_item_tooltip(self)


func _hide_tooltip() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("hide_item_tooltip"):
		tooltip_manager.hide_item_tooltip()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_clicked.emit(self)


func _get_drag_data(_at_position: Vector2) -> Variant:
	# Check if interaction is allowed (not in Battle or Resolution phase)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.current_phase == GameEnums.GamePhase.BATTLE or game_manager.current_phase == GameEnums.GamePhase.RESOLUTION:
			return null
	
	if item_type == ItemType.NONE or not item_data:
		return null
	
	_is_dragging = true
	item_drag_started.emit(self)
	
	# Create visual preview
	var preview = _create_drag_preview()
	set_drag_preview(preview)
	
	# Return drag data with type-specific keys for SlotUI drop handling
	var drag_data = {
		"source_ui": self,
		"item_type": get_item_type_string(),
		"item_data": item_data,
		"item_instance": item_instance
	}
	
	# Add type-specific keys that SlotUI expects
	match item_type:
		ItemType.MODIFIER:
			drag_data["modifier_data"] = item_data
		ItemType.PIECE:
			drag_data["piece_data"] = item_data
		ItemType.RELIC:
			drag_data["relic_data"] = item_data
			drag_data["relic_instance"] = item_instance
	
	return drag_data


func _create_drag_preview() -> Control:
	var control = Control.new()
	
	var preview_bg = ColorRect.new()
	preview_bg.size = size
	preview_bg.color = _background.color if _background else Color.GRAY
	preview_bg.modulate = Color(1, 1, 1, 0.7)
	control.add_child(preview_bg)
	
	if texture:
		var preview_tex = TextureRect.new()
		preview_tex.texture = texture
		preview_tex.size = size
		preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_tex.modulate = Color(1, 1, 1, 0.7)
		control.add_child(preview_tex)
	else:
		var preview_label = Label.new()
		preview_label.text = _label.text if _label else "?"
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.set_anchors_preset(Control.PRESET_CENTER)
		preview_label.add_theme_font_size_override("font_size", 18)
		preview_bg.add_child(preview_label)
	
	preview_bg.position = -0.5 * size
	
	return control


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_is_dragging = false
