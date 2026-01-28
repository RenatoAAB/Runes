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

# If part of the grid, this will be set.
var grid_coord: Vector2i = Vector2i(-1, -1)
# If part of the inventory, this might be the index.
var inventory_index: int = -1
# If this UI represents a slot type in inventory/shop
var is_slot_type_ui: bool = false
# Whether this slot is unlocked (can hold runes) or locked (empty space for pieces)
var is_unlocked: bool = true

var rune_ui: RuneUI
var item_ui: ItemUI  # For extra inventory items
var multi_effect_overlay: MultiEffectOverlay
var buff_rect: ColorRect
var slot_type_label: Label  # Shows multiplier badge

var current_slot_data: GridSlot

# Track which effect indices are currently highlighting this slot
var _current_effect_indices: Array = []

@export var tooltip_label_settings: LabelSettings

func _ready() -> void:
	# Create buff overlay (persistent state)
	buff_rect = ColorRect.new()
	buff_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	buff_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buff_rect.color = Color(0, 0, 0, 0)
	add_child(buff_rect)

	# Create multi-effect overlay (preview/interaction) - replaces old highlight_rect
	multi_effect_overlay = MultiEffectOverlay.new()
	multi_effect_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(multi_effect_overlay)
	
	# Ensure order: Background -> Buff -> MultiEffectOverlay -> Rune
	move_child(buff_rect, 0)
	move_child(multi_effect_overlay, 1)
	
	mouse_entered.connect(self._on_mouse_entered)
	mouse_exited.connect(self._on_mouse_exited)
	
	# Apply initial visual based on unlock state
	_update_locked_visual()


## Set whether this slot is unlocked (can hold runes) or locked (empty expansion space)
func set_locked_state(unlocked: bool) -> void:
	is_unlocked = unlocked
	_update_locked_visual()


## Update the visual appearance based on locked/unlocked state
func _update_locked_visual() -> void:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	
	if is_unlocked:
		# Unlocked slot: normal appearance, can hold runes
		style.bg_color = Color(0.15, 0.15, 0.18)
		style.set_border_width_all(2)
		style.border_color = Color(0.4, 0.4, 0.5)
	else:
		# Locked slot: darker, dashed-like appearance indicating expansion space
		style.bg_color = Color(0.08, 0.08, 0.1, 0.5)
		style.set_border_width_all(1)
		style.border_color = Color(0.25, 0.25, 0.3, 0.6)
	
	add_theme_stylebox_override("panel", style)


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
		return
	
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
	
	var text = ""
	var slot_info = current_slot_data.get_slot_info()
	
	# Show slot name if not default
	if slot_info.get("name", "Empty Slot") != "Empty Slot":
		text += "[b]%s[/b]\n" % slot_info["name"]
	
	# Show multiplier if not 1.0
	var mult = slot_info.get("multiplier", 1.0)
	if mult != 1.0:
		var mult_color = "yellow" if mult > 1.0 else "red"
		text += "[color=%s]x%.1f Multiplier[/color]\n" % [mult_color, mult]
	
	# Show upgrade level if upgraded
	var upgrade_level = slot_info.get("upgrade_level", 0)
	if upgrade_level > 0:
		text += "[color=cyan]Upgrade Lv.%d[/color]\n" % upgrade_level
	
	# Show trigger count if > 1
	var trigger_count = slot_info.get("trigger_count", 1)
	if trigger_count > 1:
		text += "[color=purple]Triggers %dx[/color]\n" % trigger_count
	
	# Show special properties
	if slot_info.get("preserves_charges", false):
		text += "[color=green]Preserves Charges[/color]\n"
	
	if slot_info.get("protects_fragile", false):
		text += "[color=green]Protects Fragile[/color]\n"
	
	if slot_info.get("is_broken", false):
		text += "[color=red]BROKEN (x0.5)[/color]\n"
	
	# Show active states
	for state_id in current_slot_data.active_states:
		var data = current_slot_data.active_states[state_id]
		var state_desc = _get_state_description(state_id)
		var duration_text = "(permanent)" if data["duration"] > 9999 else "(%d turns)" % data["duration"]
		var state_name = state_id.capitalize().replace("_", " ")
		text += "[color=yellow]%s[/color] %s\n" % [state_name, duration_text]
		if state_desc != "":
			text += "%s\n" % state_desc
		if data.get("score_bonus", 0) != 0:
			text += "[color=cyan]+%d Score[/color]\n" % data["score_bonus"]
		if data.get("activation_bonus", 0) != 0:
			text += "[color=cyan]+%d Activations[/color]\n" % data["activation_bonus"]
		if data.get("multiplier_bonus", 0.0) != 0.0:
			text += "[color=yellow]+%.1fx Mult[/color]\n" % data["multiplier_bonus"]
	
	# Only show tooltip if there's content
	if text.strip_edges().length() > 0:
		var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
		if tooltip_manager:
			tooltip_manager.set_slot_tooltip(text)

func _get_state_description(state_id: String) -> String:
	match state_id:
		"petrified":
			return "Rune cannot be moved from this slot."
		"lead_residue":
			return "Blocks gold effect. Slot is contaminated."
		"illuminated":
			return "Grants bonus activations to runes."
		"burning":
			return "Increases score from runes."
		"wet":
			return "Grants bonus activations."
		"electrified":
			return "Enables special metal synergies."
		"prismatic":
			return "Refracts light in all directions."
		_:
			return ""

func _on_mouse_exited() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.clear_slot_tooltip()
		if tooltip_manager.has_method("hide_item_tooltip"):
			tooltip_manager.hide_item_tooltip()
		tooltip_manager.hide_tooltip()


func set_rune(rune: RuneInstance) -> void:
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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
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
		return not is_unlocked
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_ui = data.get("source_ui")
	var source_slot_ui = null
	if source_ui and source_ui.get_parent() is SlotUI:
		source_slot_ui = source_ui.get_parent()
	
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

## Enable/disable shop mode for this slot (shows price label)
func set_shop_mode(enabled: bool, price_text: String = "") -> void:
	_shop_mode = enabled
	_shop_price_text = price_text
	
	if enabled:
		if not _price_label:
			_price_label = Label.new()
			_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_price_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			_price_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			_price_label.add_theme_font_size_override("font_size", 10)
			add_child(_price_label)
		
		_price_label.text = price_text
		_price_label.visible = true
		
		# Color based on price text
		if price_text == "FREE!":
			_price_label.add_theme_color_override("font_color", Color.LIME)
		elif price_text.begins_with("$"):
			_price_label.add_theme_color_override("font_color", Color.GOLD)
		else:
			_price_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		if _price_label:
			_price_label.visible = false


## Set shop item data for tooltip display
func set_shop_item(item_type: String, item_data: Variant) -> void:
	_shop_item_type = item_type
	_shop_item_data = item_data


## Show tooltip for shop item
func _show_shop_item_tooltip() -> void:
	if not _shop_item_data:
		return
	
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if not tooltip_manager:
		return
	
	var text = ""
	
	match _shop_item_type:
		"piece":
			var piece = _shop_item_data as SlotPieceData
			if piece:
				text = "[b]%s[/b]\n" % piece.display_name
				text += "[color=yellow]%d slots[/color]\n" % piece.get_slot_count()
				if piece.description and not piece.description.is_empty():
					text += "[color=silver]%s[/color]\n" % piece.description
				text += "[color=gold]%s[/color]" % _shop_price_text
		
		"modifier":
			var modifier = _shop_item_data as SlotModifierData
			if modifier:
				text = "[b]%s[/b]\n" % modifier.display_name
				text += "[color=cyan]%s[/color]\n" % _get_modifier_type_name(modifier.modifier_type)
				if modifier.slot_data_override:
					text += "[color=orange]Tipo de Slot:[/color] %s\n" % modifier.slot_data_override.slot_name
					var slot_desc = modifier.slot_data_override.get_full_description()
					if slot_desc and not slot_desc.is_empty():
						text += "[color=gray]%s[/color]\n" % slot_desc
				if modifier.description and not modifier.description.is_empty():
					text += "[color=silver]%s[/color]\n" % modifier.description
				else:
					text += "[color=silver]%s[/color]\n" % _get_modifier_auto_description(modifier)
				text += "[color=gold]%s[/color]" % _shop_price_text
		
		"relic":
			var relic = _shop_item_data as RelicData
			if relic:
				text = "[b]%s[/b]\n" % relic.display_name
				if relic.description and not relic.description.is_empty():
					text += "[color=silver]%s[/color]\n" % relic.description
				text += "[color=gold]%s[/color]" % _shop_price_text
	
	if text != "":
		tooltip_manager.show_tooltip(text, false)


func _get_modifier_type_name(type: SlotModifierData.ModifierType) -> String:
	match type:
		SlotModifierData.ModifierType.MULTIPLIER: return "Multiplier"
		SlotModifierData.ModifierType.TRIGGER: return "Trigger"
		SlotModifierData.ModifierType.ECONOMY: return "Economy"
		SlotModifierData.ModifierType.PRESERVATION: return "Preservation"
		SlotModifierData.ModifierType.PROTECTION: return "Protection"
		SlotModifierData.ModifierType.STATE: return "State"
		_: return "Unknown"


func _get_modifier_auto_description(data: SlotModifierData) -> String:
	match data.modifier_type:
		SlotModifierData.ModifierType.MULTIPLIER:
			return "Adds +%.1fx multiplier to this slot." % data.value
		SlotModifierData.ModifierType.TRIGGER:
			return "Slot triggers %d extra time(s)." % int(data.value)
		SlotModifierData.ModifierType.ECONOMY:
			return "Generates $%d per activation." % int(data.value)
		SlotModifierData.ModifierType.PRESERVATION:
			return "Runes in this slot don't consume charges."
		SlotModifierData.ModifierType.PROTECTION:
			return "Protects fragile runes from breaking."
		SlotModifierData.ModifierType.STATE:
			return "Applies a special state to the slot."
		_:
			return ""


## Display a slot type (SlotData) instead of a rune
func update_slot_data_display(slot_data: SlotData) -> void:
	# Clear any rune display
	if rune_ui:
		rune_ui.queue_free()
		rune_ui = null
	
	# Update background color based on slot type
	var style = StyleBoxFlat.new()
	style.bg_color = slot_data.color_tint if slot_data.color_tint else Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.border_color = slot_data.color_tint.lightened(0.3) if slot_data.color_tint else Color.GRAY
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	
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
	
	# Update background
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(2)
	style.border_color = bg_color.lightened(0.3)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	
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
	
	# Reset to default style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)


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
		item_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_ui.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(item_ui)
	
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
