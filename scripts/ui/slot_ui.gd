class_name SlotUI
extends PanelContainer

## Visual representation of a GridSlot or Inventory Slot.
## Handles the Drop part of Drag & Drop for both runes and slots.
## Supports multi-effect visualization when multiple effects target this slot.
## Also supports ExtraInventory items (relics, modifiers, pieces) via ItemUI.
## Grid slots can be in two states:
##   - UNLOCKED: Can hold runes, can receive modifiers
##   - LOCKED: Empty space, can receive slot pieces to unlock

signal rune_dropped(source_rune: RuneInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)
signal slot_type_dropped(source_slot: SlotInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)
signal extra_item_dropped(item_type: String, item_data: Variant, item_instance: Variant, target_slot_ui: SlotUI)
signal modifier_dropped(modifier: SlotModifierData, target_slot_ui: SlotUI)
signal piece_dropped(piece: SlotPieceData, target_slot_ui: SlotUI)
signal relic_slot_dropped(relic: RelicInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)
signal relic_slot_clicked(relic: RelicInstance)

## Context type that defines which sprite this slot displays.
enum SlotContext { PANEL, RELIC, INVENTORY, SHOP }

@export_group("Slot Sprites")
@export var texture_panel_empty: Texture2D    ## Unlocked panel slot (no modifier)
@export var texture_panel_modified: Texture2D ## Panel slot that has a slot modifier
@export var texture_panel_locked: Texture2D   ## Locked expansion panel slot
@export var texture_relic: Texture2D          ## Relic container slot
@export var texture_inventory: Texture2D      ## Inventory slot
@export var texture_shop: Texture2D           ## Shop slot

## Current visual context — call set_slot_context() to change it.
var slot_context: SlotContext = SlotContext.PANEL
## Reference to the Sprite2D child that shows the slot frame.
var _slot_sprite: Sprite2D = null
var _base_slot_texture: Texture2D = null
var _modifier_texture_cache: Dictionary = {}

# If part of the grid, this will be set.
var grid_coord: Vector2i = Vector2i(-1, -1)
# If part of the inventory, this might be the index.
var inventory_index: int = -1
# If this UI represents a slot type in inventory/shop
var is_slot_type_ui: bool = false
# Whether this slot is unlocked (can hold runes) or locked (empty space for pieces)
var is_unlocked: bool = true
# Whether this slot acts as a relic container
var is_relic_slot: bool = false
var relic_slot_index: int = 0
var relic_panel_index: int = 0
var _relic_instance: RelicInstance = null

var rune_ui: RuneUI
var item_ui: ItemUI  # For extra inventory items
var multi_effect_overlay: MultiEffectOverlay
var buff_rect: ColorRect
var residue_visual: ResidueVisual
var slot_type_label: Label  # Shows multiplier badge

var current_slot_data: GridSlot

# Track which effect indices are currently highlighting this slot
var _current_effect_indices: Array = []

@export var tooltip_label_settings: LabelSettings

func _ready() -> void:
	clip_contents = true

	# Get the sprite child and clear the PanelContainer background fill
	_slot_sprite = get_node_or_null("Sprite2D")
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if _slot_sprite and _slot_sprite.texture:
		_base_slot_texture = _slot_sprite.texture
	elif texture_panel_empty:
		_base_slot_texture = texture_panel_empty
	_prepare_context_fallback_textures()

	# Create buff overlay (persistent state)
	buff_rect = ColorRect.new()
	buff_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	buff_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buff_rect.color = Color(0, 0, 0, 0)
	add_child(buff_rect)

	# Create residue visual overlay (shader effects for mana residue/anomaly)
	residue_visual = ResidueVisual.new()
	residue_visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(residue_visual)

	# Create multi-effect overlay (preview/interaction) - replaces old highlight_rect
	multi_effect_overlay = MultiEffectOverlay.new()
	multi_effect_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(multi_effect_overlay)
	
	# Ensure order: Sprite background -> Buff -> Residue/Rune/Item -> MultiEffectOverlay on top.
	if _slot_sprite:
		move_child(_slot_sprite, 0)
	move_child(buff_rect, 1)
	move_child(residue_visual, -1)
	move_child(multi_effect_overlay, -1)
	
	mouse_entered.connect(self._on_mouse_entered)
	mouse_exited.connect(self._on_mouse_exited)
	
	# Apply initial sprite based on slot context
	_refresh_slot_sprite()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var mc = get_tree().get_first_node_in_group("main_controller")
		if mc and mc.has_method("clear_piece_drag_preview"):
			mc.clear_piece_drag_preview()


## Set whether this slot is unlocked (can hold runes) or locked (empty expansion space)
func set_locked_state(unlocked: bool) -> void:
	is_unlocked = unlocked
	_update_locked_visual()


## Update the visual appearance based on locked/unlocked state
func _update_locked_visual() -> void:
	_refresh_slot_sprite()


## Set the slot context to switch which sprite is displayed.
func set_slot_context(context: SlotContext) -> void:
	slot_context = context
	_refresh_slot_sprite()


## Refresh the sprite texture based on current context and unlock state.
func _refresh_slot_sprite() -> void:
	if not _slot_sprite:
		return
	_slot_sprite.self_modulate = Color.WHITE
	match slot_context:
		SlotContext.RELIC:
			_slot_sprite.texture = texture_relic if texture_relic else texture_panel_empty
		SlotContext.INVENTORY:
			_slot_sprite.texture = texture_inventory if texture_inventory else texture_panel_empty
		SlotContext.SHOP:
			_slot_sprite.texture = texture_shop if texture_shop else texture_panel_empty
		SlotContext.PANEL:
			if not is_unlocked:
				_slot_sprite.texture = texture_panel_locked if texture_panel_locked else texture_panel_empty
			else:
				_slot_sprite.texture = texture_panel_empty


func _prepare_context_fallback_textures() -> void:
	if not _base_slot_texture:
		if texture_panel_empty:
			_base_slot_texture = texture_panel_empty
		else:
			return

	if not texture_panel_empty:
		texture_panel_empty = _base_slot_texture
	if not texture_panel_locked:
		texture_panel_locked = _build_tinted_texture(_base_slot_texture, Color(0.45, 0.45, 0.5, 1.0), 0.7)
	if not texture_inventory:
		texture_inventory = _build_tinted_texture(_base_slot_texture, Color(0.45, 0.95, 0.7, 1.0), 1.0)
	if not texture_relic:
		texture_relic = _build_tinted_texture(_base_slot_texture, Color(0.95, 0.85, 0.35, 1.0), 1.0)
	if not texture_shop:
		texture_shop = _build_tinted_texture(_base_slot_texture, Color(0.55, 0.78, 1.0, 1.0), 1.0)
	if not texture_panel_modified:
		texture_panel_modified = _build_tinted_texture(_base_slot_texture, Color(1.0, 0.82, 0.45, 1.0), 1.0)


func _build_tinted_texture(source: Texture2D, tint: Color, brightness: float = 1.0) -> Texture2D:
	if not source:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			var mixed := Color(
				clampf(pixel.r * tint.r * brightness, 0.0, 1.0),
				clampf(pixel.g * tint.g * brightness, 0.0, 1.0),
				clampf(pixel.b * tint.b * brightness, 0.0, 1.0),
				pixel.a
			)
			image.set_pixel(x, y, mixed)
	return ImageTexture.create_from_image(image)


func _get_modifier_texture(slot_data: SlotData, modifier_key: String = "") -> Texture2D:
	if not slot_data:
		return texture_panel_modified
	if slot_data.texture:
		return slot_data.texture

	var key := modifier_key
	if key.is_empty():
		key = slot_data.id if not slot_data.id.is_empty() else slot_data.slot_name
	if key.is_empty() or not _base_slot_texture:
		return texture_panel_modified

	if _modifier_texture_cache.has(key):
		return _modifier_texture_cache[key] as Texture2D

	var hue := float(abs(key.hash()) % 360) / 360.0
	var generated := _build_tinted_texture(_base_slot_texture, Color.from_hsv(hue, 0.55, 1.0, 1.0), 1.0)
	_modifier_texture_cache[key] = generated
	return generated


## Sets effect highlighting using the new multi-effect system.
## Pass an array of effect indices to show, or empty array to clear.
func set_effect_highlight(effect_indices: Array) -> void:
	_current_effect_indices = effect_indices.duplicate()
	if multi_effect_overlay:
		multi_effect_overlay.set_effect_indices(effect_indices)

## Sets condition highlight (green border).
func set_condition_highlight(has_condition: bool) -> void:
	if multi_effect_overlay:
		multi_effect_overlay.set_condition_highlight(has_condition)

## Sets value source highlight (dashed border in effect color).
func set_value_source_highlight(effect_indices: Array) -> void:
	if multi_effect_overlay:
		multi_effect_overlay.set_value_source_indices(effect_indices)

## Legacy method for backwards compatibility - converts single color to effect index.
## Deprecated: use set_effect_highlight instead.
func set_highlight(color: Color) -> void:
	if color.a < 0.01:
		set_effect_highlight([])
	else:
		# For legacy support, we can't determine the exact effect index
		# So we just use index 0 for any non-clear color
		set_effect_highlight([0])

## Returns the current effect indices highlighting this slot.
func get_effect_indices() -> Array:
	return _current_effect_indices.duplicate()

func set_buff_highlight(color: Color) -> void:
	if buff_rect:
		buff_rect.color = color

func update_slot_info(slot: GridSlot) -> void:
	current_slot_data = slot
	if not slot:
		set_buff_highlight(Color(0, 0, 0, 0))
		if residue_visual:
			residue_visual.clear()
		if slot_context == SlotContext.PANEL:
			_refresh_slot_sprite()
		return

	if slot_context == SlotContext.PANEL and slot.slot:
		var modifier_key := slot.slot.slot_modifier_id
		if modifier_key.is_empty():
			var applied_modifiers = slot.slot.get_meta("applied_modifiers", {})
			if applied_modifiers is Dictionary and applied_modifiers.size() > 0:
				modifier_key = String(applied_modifiers.keys()[0])

		if not modifier_key.is_empty() or (slot.slot.data and slot.slot.data.id != "default"):
			var modifier_texture := _get_modifier_texture(slot.slot.data, modifier_key)
			if _slot_sprite and modifier_texture:
				_slot_sprite.texture = modifier_texture
				if slot.slot.data and slot.slot.data.color_tint != Color.WHITE:
					_slot_sprite.self_modulate = slot.slot.data.color_tint
				else:
					_slot_sprite.self_modulate = Color.WHITE
		else:
			_refresh_slot_sprite()
	
	# Update residue visual overlay
	if residue_visual and slot.slot:
		residue_visual.update_residues(slot.slot.get_residue_ids())
	elif residue_visual:
		residue_visual.clear()
	
	# Update visual based on slot properties
	var highlight_color = Color(0, 0, 0, 0)
	
	# Check for active states
	if not slot.active_states.is_empty():
		highlight_color = Color(0.2, 0.2, 1.0, 0.3)
	
	# Check for slot multiplier bonus
	if slot.get_multiplier() > 1.0:
		highlight_color = Color(0.8, 0.6, 0.0, 0.3)  # Gold for multiplier
	elif slot.get_multiplier() < 1.0:
		highlight_color = Color(0.5, 0.0, 0.0, 0.3)  # Red for penalty
	
	# Check for special properties
	if slot.preserves_charges():
		highlight_color = Color(0.0, 0.8, 0.4, 0.3)  # Green for preserve
	
	if slot.get_trigger_count() > 1:
		highlight_color = Color(0.6, 0.0, 0.8, 0.3)  # Purple for repeater
	
	set_buff_highlight(highlight_color)

func _on_mouse_entered() -> void:
	# Handle shop item tooltip first
	if _shop_mode and _shop_item_data:
		_show_shop_item_tooltip()
		return
	
	if not current_slot_data:
		return
	
	var text = TooltipBuilder.build_slot_tooltip(current_slot_data)
	
	if text.strip_edges().length() > 0:
		var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
		if tooltip_manager:
			tooltip_manager.set_slot_tooltip(text)

func _on_mouse_exited() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.clear_slot_tooltip()
		if tooltip_manager.has_method("hide_item_tooltip"):
			tooltip_manager.hide_item_tooltip()
		tooltip_manager.hide_tooltip()


## Handle click on relic slots to remove the relic
func _gui_input(event: InputEvent) -> void:
	if not is_relic_slot or not _relic_instance:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		relic_slot_clicked.emit(_relic_instance)


## Handle dragging relics out of relic slots
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not is_relic_slot or not _relic_instance:
		return null

	# Check phase
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.current_phase == GameEnums.GamePhase.BATTLE or game_manager.current_phase == GameEnums.GamePhase.RESOLUTION:
			return null

	# Create preview
	var preview = TextureRect.new()
	if _relic_instance.data and _relic_instance.data.icon:
		preview.texture = _relic_instance.data.icon
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = Vector2(48, 48)
	preview.size = Vector2(48, 48)
	preview.modulate = Color(1, 1, 1, 0.7)

	var control = Control.new()
	control.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(control)

	# Start breathing animation on the preview
	var juice = get_node_or_null("/root/JuiceManager")
	if juice:
		juice.start_breathing_on_preview(preview)

	return {
		"source_ui": self,
		"source_type": "relic_slot",
		"relic_instance": _relic_instance,
		"item_type": "relic",
		"item_instance": _relic_instance,
		"panel_index": relic_panel_index,
		"slot_index": relic_slot_index
	}


func set_rune(rune: RuneInstance) -> void:
	# If this is a relic slot, ignore rune set calls
	if is_relic_slot:
		return
	# Clear existing UI
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	if rune:
		# Create new RuneUI
		# In a real project, we would instantiate a PackedScene.
		# For this script-only task, we create it programmatically.
		rune_ui = RuneUI.new()
		rune_ui.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rune_ui.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rune_ui.custom_minimum_size = Vector2(32, 32)
		add_child(rune_ui)
		rune_ui.setup(rune)
		# Keep overlay above all visuals for clear targeting/condition feedback.
		if residue_visual:
			move_child(residue_visual, -1)
		if multi_effect_overlay:
			move_child(multi_effect_overlay, -1)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	# Relic slots accept relic data only
	if is_relic_slot:
		if _relic_instance != null:
			return false  # Already has a relic
		if data.has("relic_instance") and data.relic_instance != null:
			return true
		if data.get("item_type") == "relic" and data.has("item_instance"):
			return true
		return false
	
	# Can drop rune instances only on UNLOCKED slots
	if data.has("rune_instance") and not data.has("source_type"):
		return is_unlocked
	
	# Can drop relics FROM relic slots back to inventory (other_inventory slots only)
	if data.get("source_type") == "relic_slot" and data.has("relic_instance"):
		# Only accept on inventory slots (not grid slots)
		return grid_coord == Vector2i(-1, -1)
	
	# Can drop slot types (for replacing slot on grid) on UNLOCKED slots
	if data.has("slot_instance") and grid_coord != Vector2i(-1, -1):
		return is_unlocked
	
	# Can drop MODIFIERS on UNLOCKED grid slots
	if data.has("modifier_data") and grid_coord != Vector2i(-1, -1):
		return is_unlocked
	
	# Can drop PIECES on LOCKED grid slots (to expand the panel)
	if data.has("piece_data") and grid_coord != Vector2i(-1, -1):
		# Request drag preview highlighting on the grid
		var mc = get_tree().get_first_node_in_group("main_controller")
		if not is_unlocked:
			if mc and mc.has_method("show_piece_drag_preview"):
				mc.show_piece_drag_preview(data["piece_data"], grid_coord)
		else:
			# Hovering unlocked slot with a piece — clear any previous preview
			if mc and mc.has_method("clear_piece_drag_preview"):
				mc.clear_piece_drag_preview()
		return not is_unlocked
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_ui = data.get("source_ui")
	var source_slot_ui = null
	if source_ui is SlotUI:
		source_slot_ui = source_ui
	elif source_ui and source_ui.get_parent() is SlotUI:
		source_slot_ui = source_ui.get_parent()
	
	# Handle relic drop onto a relic slot
	if is_relic_slot:
		var dropped_relic: RelicInstance = null
		if data.has("relic_instance"):
			dropped_relic = data.relic_instance as RelicInstance
		elif data.get("item_type") == "relic" and data.has("item_instance"):
			dropped_relic = data.item_instance as RelicInstance
		if dropped_relic:
			relic_slot_dropped.emit(dropped_relic, self, source_slot_ui)
		return
	
	# Handle relic drop from relic slot back to inventory
	if data.get("source_type") == "relic_slot" and data.has("relic_instance"):
		extra_item_dropped.emit("relic", data.get("relic_instance").data, data.get("relic_instance"), self)
		return
	
	# Handle rune drop
	if data.has("rune_instance"):
		rune_dropped.emit(data["rune_instance"], self, source_slot_ui)
	
	# Handle slot type drop
	elif data.has("slot_instance"):
		slot_type_dropped.emit(data["slot_instance"], self, source_slot_ui)
	
	# Handle modifier drop on unlocked slot
	elif data.has("modifier_data"):
		modifier_dropped.emit(data["modifier_data"], self)
	
	# Handle piece drop on locked slot
	elif data.has("piece_data"):
		piece_dropped.emit(data["piece_data"], self)


# --- Shop Mode Support ---

var _shop_mode: bool = false
var _shop_price_text: String = ""  # Price text for tooltip display
var _price_label: Label = null
var _placeholder_label: Label = null

## Shop item data for tooltips
var _shop_item_type: String = ""  # "piece", "modifier", "relic", "rune"
var _shop_item_data: Variant = null  # SlotPieceData, SlotModifierData, RelicData, RuneData

## Get the current price text for tooltip display
func get_shop_price_text() -> String:
	return _shop_price_text if _shop_mode else ""

## Enable/disable shop mode for this slot (price shown only in tooltip)
func set_shop_mode(enabled: bool, price_text: String = "") -> void:
	_shop_mode = enabled
	_shop_price_text = price_text


## Set shop item data for tooltip display
func set_shop_item(item_type: String, item_data: Variant) -> void:
	_shop_item_type = item_type
	_shop_item_data = item_data


## Show tooltip for shop item — delegates to centralized TooltipBuilder
func _show_shop_item_tooltip() -> void:
	if not _shop_item_data:
		return
	
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if not tooltip_manager:
		return
	
	var price = _shop_price_text
	var text = ""
	
	match _shop_item_type:
		"piece":
			var piece = _shop_item_data as SlotPieceData
			if piece:
				text = TooltipBuilder.build_piece_tooltip(piece, price)
		"modifier":
			var modifier = _shop_item_data as SlotModifierData
			if modifier:
				text = TooltipBuilder.build_modifier_tooltip(modifier, price)
		"relic":
			var relic = _shop_item_data as RelicData
			if relic:
				text = TooltipBuilder.build_relic_tooltip(relic, null, price)
	
	if text != "":
		tooltip_manager.show_tooltip(text, false)


## Display a slot type (SlotData) instead of a rune
func update_slot_data_display(slot_data: SlotData) -> void:
	# Clear any rune display
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	# Update sprite for modified slot — use SlotData's own texture when available
	if _slot_sprite:
		var tex = _get_modifier_texture(slot_data)
		if tex:
			_slot_sprite.texture = tex
		_slot_sprite.self_modulate = slot_data.color_tint if slot_data.color_tint != Color.WHITE else Color.WHITE
	
	# Show multiplier badge
	if not slot_type_label:
		slot_type_label = Label.new()
		slot_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_type_label.set_anchors_preset(Control.PRESET_CENTER)
		slot_type_label.add_theme_font_size_override("font_size", 14)
		add_child(slot_type_label)
	
	# Build display text
	var display_text = ""
	if slot_data.base_multiplier != 1.0:
		display_text = "x%.1f" % slot_data.base_multiplier
	elif slot_data.trigger_count > 1:
		display_text = "%dx" % slot_data.trigger_count
	elif slot_data.preserves_charges:
		display_text = "∞"
	else:
		display_text = slot_data.slot_name.substr(0, 3).to_upper()
	
	slot_type_label.text = display_text
	slot_type_label.visible = true


## Show placeholder display (for relics, etc.)
func set_placeholder_display(text: String, bg_color: Color = Color(0.2, 0.2, 0.2)) -> void:
	# Clear any rune display
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	# Tint the sprite to communicate the placeholder category
	if _slot_sprite:
		_slot_sprite.self_modulate = bg_color
	
	# Show placeholder text
	if not _placeholder_label:
		_placeholder_label = Label.new()
		_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_placeholder_label.set_anchors_preset(Control.PRESET_CENTER)
		_placeholder_label.add_theme_font_size_override("font_size", 24)
		add_child(_placeholder_label)
	
	_placeholder_label.text = text
	_placeholder_label.visible = true


## Clear all display (rune, slot type, placeholder)
func clear_display() -> void:
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	if slot_type_label:
		slot_type_label.visible = false
	
	if _placeholder_label:
		_placeholder_label.visible = false
	
	if _price_label:
		_price_label.visible = false
	
	# Clear item_ui if present
	if item_ui:
		item_ui.queue_free()
		item_ui = null
	
	# Reset sprite to context-appropriate texture
	_refresh_slot_sprite()


## Set an extra inventory item (relic, modifier, piece) using ItemUI
func set_extra_item(item_type: String, data: Variant, instance: Variant = null) -> void:
	# Clear any existing rune display
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	if _placeholder_label:
		_placeholder_label.visible = false
	
	# Create or reuse ItemUI
	if not item_ui:
		item_ui = ItemUI.new()
		item_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(item_ui)

	# Keep overlay above item visuals too.
	if multi_effect_overlay:
		move_child(multi_effect_overlay, -1)
	
	# Set the item based on type
	match item_type:
		"relic":
			if instance:
				item_ui.set_relic(instance as RelicInstance)
			else:
				item_ui.set_relic_data(data as RelicData)
		"modifier":
			item_ui.set_modifier(data as SlotModifierData)
		"piece":
			if instance:
				item_ui.set_piece(instance as SlotPieceInstance)
			else:
				item_ui.set_piece_data(data as SlotPieceData)


## Check if this slot has an extra item
func has_extra_item() -> bool:
	return item_ui != null and item_ui.item_type != ItemUI.ItemType.NONE


## Get the item_ui if present
func get_item_ui() -> ItemUI:
	return item_ui
