class_name ExtraInventoryUI
extends PanelContainer

## UI component for displaying non-rune items: relics, modifiers, and slot pieces.
## Provides a tabbed or sectioned view of different item types.

signal relic_selected(relic: RelicInstance)
signal modifier_selected(modifier: SlotModifierData)
signal piece_selected(piece: SlotPieceInstance)
signal item_drag_started(item: Variant, item_type: String)

@export var section_height: int = 100
@export var item_spacing: int = 5
@export var item_size: Vector2 = Vector2(50, 50)

var main_container: VBoxContainer
var relic_section: VBoxContainer
var modifier_section: VBoxContainer
var piece_section: VBoxContainer

var relic_items_container: HBoxContainer
var modifier_items_container: HBoxContainer
var piece_items_container: HBoxContainer

var extra_inventory: ExtraInventoryManager = null


func _ready() -> void:
	_setup_ui()
	
	# Try to find ExtraInventoryManager
	await get_tree().process_frame
	extra_inventory = get_tree().get_first_node_in_group("extra_inventory")
	if extra_inventory:
		extra_inventory.inventory_changed.connect(_refresh_all)
		_refresh_all()


func _setup_ui() -> void:
	custom_minimum_size = Vector2(300, 350)
	
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 10)
	add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "Extra Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	main_container.add_child(title)
	
	# Relic section
	relic_section = _create_section("Relics", "relic")
	relic_items_container = relic_section.get_node("ItemsScroll/Items") as HBoxContainer
	main_container.add_child(relic_section)
	
	# Modifier section
	modifier_section = _create_section("Modifiers", "modifier")
	modifier_items_container = modifier_section.get_node("ItemsScroll/Items") as HBoxContainer
	main_container.add_child(modifier_section)
	
	# Piece section
	piece_section = _create_section("Slot Pieces", "piece")
	piece_items_container = piece_section.get_node("ItemsScroll/Items") as HBoxContainer
	main_container.add_child(piece_section)


func _create_section(title_text: String, section_type: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.name = title_text.replace(" ", "") + "Section"
	section.custom_minimum_size.y = section_height
	
	# Header
	var header = HBoxContainer.new()
	section.add_child(header)
	
	var title = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)
	
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = "(0)"
	count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(count_label)
	
	# Scrollable items container
	var scroll = ScrollContainer.new()
	scroll.name = "ItemsScroll"
	scroll.custom_minimum_size.y = item_size.y + 10
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section.add_child(scroll)
	
	var items = HBoxContainer.new()
	items.name = "Items"
	items.add_theme_constant_override("separation", item_spacing)
	scroll.add_child(items)
	
	return section


## Refresh all sections
func _refresh_all() -> void:
	if not extra_inventory:
		return
	
	_refresh_relics()
	_refresh_modifiers()
	_refresh_pieces()


## Refresh relics section
func _refresh_relics() -> void:
	if not relic_items_container or not extra_inventory:
		return
	
	# Clear existing
	for child in relic_items_container.get_children():
		child.queue_free()
	
	# Add relics
	var relics = extra_inventory.get_available_relics()
	for relic in relics:
		var item_ui = _create_relic_item(relic)
		relic_items_container.add_child(item_ui)
	
	# Update count
	var count_label = relic_section.get_node_or_null("HBoxContainer/CountLabel") as Label
	if not count_label:
		count_label = relic_section.get_child(0).get_child(1) as Label
	if count_label:
		count_label.text = "(%d/%d)" % [extra_inventory.relics.size(), extra_inventory.max_relics]


## Refresh modifiers section
func _refresh_modifiers() -> void:
	if not modifier_items_container or not extra_inventory:
		return
	
	# Clear existing
	for child in modifier_items_container.get_children():
		child.queue_free()
	
	# Add modifiers
	for modifier in extra_inventory.modifiers:
		var item_ui = _create_modifier_item(modifier)
		modifier_items_container.add_child(item_ui)
	
	# Update count
	var count_label = modifier_section.get_child(0).get_child(1) as Label
	if count_label:
		count_label.text = "(%d/%d)" % [extra_inventory.modifiers.size(), extra_inventory.max_modifiers]


## Refresh pieces section
func _refresh_pieces() -> void:
	if not piece_items_container or not extra_inventory:
		return
	
	# Clear existing
	for child in piece_items_container.get_children():
		child.queue_free()
	
	# Add pieces
	var pieces = extra_inventory.get_available_slot_pieces()
	for piece in pieces:
		var item_ui = _create_piece_item(piece)
		piece_items_container.add_child(item_ui)
	
	# Update count
	var count_label = piece_section.get_child(0).get_child(1) as Label
	if count_label:
		count_label.text = "(%d/%d)" % [extra_inventory.slot_pieces.size(), extra_inventory.max_slot_pieces]


func _create_relic_item(relic: RelicInstance) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = item_size
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.clip_contents = true
	
	var style = StyleBoxFlat.new()
	style.bg_color = _get_rarity_color(relic.data.rarity)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	item.add_theme_stylebox_override("panel", style)
	
	if relic.data.icon:
		var icon = TextureRect.new()
		icon.texture = relic.data.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
	else:
		var label = Label.new()
		label.text = relic.data.display_name.substr(0, 2).to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item.add_child(label)
	
	item.gui_input.connect(_on_relic_input.bind(relic))
	item.mouse_entered.connect(_on_item_hover.bind(relic, "relic"))
	item.mouse_exited.connect(_on_item_unhover)
	
	return item


func _create_modifier_item(modifier: SlotModifierData) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = item_size
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.clip_contents = true
	
	var style = StyleBoxFlat.new()
	style.bg_color = _get_rarity_color(modifier.rarity)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	item.add_theme_stylebox_override("panel", style)
	
	if modifier.icon:
		var icon = TextureRect.new()
		icon.texture = modifier.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
	else:
		var label = Label.new()
		label.text = modifier.display_name.substr(0, 2).to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item.add_child(label)
	
	item.gui_input.connect(_on_modifier_input.bind(modifier))
	item.mouse_entered.connect(_on_item_hover.bind(modifier, "modifier"))
	item.mouse_exited.connect(_on_item_unhover)
	
	return item


func _create_piece_item(piece: SlotPieceInstance) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = item_size
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item.clip_contents = true
	
	var style = StyleBoxFlat.new()
	style.bg_color = _get_rarity_color(piece.data.rarity)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	item.add_theme_stylebox_override("panel", style)
	
	# Use SlotPiecePreviewGrid to draw the piece shape with slot-styled cells
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(center)
	
	var preview_grid = SlotPiecePreviewGrid.new()
	preview_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(preview_grid)
	# Auto-fit to fill the item area (minus margins)
	var fit_area = item_size - Vector2(12, 12)
	preview_grid.setup_auto_fit_instance(piece, fit_area, 2)
	
	item.gui_input.connect(_on_piece_input.bind(piece))
	item.mouse_entered.connect(_on_item_hover.bind(piece, "piece"))
	item.mouse_exited.connect(_on_item_unhover)
	
	return item


func _get_rarity_color(rarity: GameEnums.Rarity) -> Color:
	match rarity:
		GameEnums.Rarity.COMMON:
			return Color(0.3, 0.3, 0.3)
		GameEnums.Rarity.UNCOMMON:
			return Color(0.2, 0.5, 0.2)
		GameEnums.Rarity.RARE:
			return Color(0.2, 0.3, 0.6)
		GameEnums.Rarity.EPIC:
			return Color(0.4, 0.2, 0.5)
		GameEnums.Rarity.LEGENDARY:
			return Color(0.6, 0.4, 0.1)
		_:
			return Color(0.2, 0.2, 0.2)


func _on_relic_input(event: InputEvent, relic: RelicInstance) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		relic_selected.emit(relic)
		item_drag_started.emit(relic, "relic")


func _on_modifier_input(event: InputEvent, modifier: SlotModifierData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		modifier_selected.emit(modifier)
		item_drag_started.emit(modifier, "modifier")


func _on_piece_input(event: InputEvent, piece: SlotPieceInstance) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		piece_selected.emit(piece)
		item_drag_started.emit(piece, "piece")


func _on_item_hover(item: Variant, item_type: String) -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if not tooltip_manager or not tooltip_manager.has_method("show_tooltip"):
		return
	
	var text = ""
	match item_type:
		"relic":
			var relic = item as RelicInstance
			text = "[b]%s[/b]\n%s" % [relic.data.display_name, relic.data.get_full_description()]
		"modifier":
			var modifier = item as SlotModifierData
			text = "[b]%s[/b]\n%s" % [modifier.display_name, modifier.get_full_description()]
		"piece":
			var piece = item as SlotPieceInstance
			var info = piece.get_display_info()
			text = "[b]%s[/b]\n%d slot(s)\n%s" % [info.name, info.slot_count, piece.data.description]
	
	tooltip_manager.show_tooltip(text, self)


func _on_item_unhover() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
		tooltip_manager.hide_tooltip()
