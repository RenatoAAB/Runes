class_name SlotUI
extends PanelContainer

## Visual representation of a GridSlot or Inventory Slot.
## Handles the Drop part of Drag & Drop for both runes and slots.
## Supports multi-effect visualization when multiple effects target this slot.

signal rune_dropped(source_rune: RuneInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)
signal slot_type_dropped(source_slot: SlotInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)

# If part of the grid, this will be set.
var grid_coord: Vector2i = Vector2i(-1, -1)
# If part of the inventory, this might be the index.
var inventory_index: int = -1
# If this UI represents a slot type in inventory/shop
var is_slot_type_ui: bool = false

var rune_ui: RuneUI
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
	
	# Can drop rune instances
	if data.has("rune_instance"):
		return true
	
	# Can drop slot types (for replacing slot on grid)
	if data.has("slot_instance") and grid_coord != Vector2i(-1, -1):
		return true
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_ui = data.get("source_ui")
	var source_slot_ui = null
	if source_ui and source_ui.get_parent() is SlotUI:
		source_slot_ui = source_ui.get_parent()
	
	# Handle rune drop
	if data.has("rune_instance"):
		rune_dropped.emit(data["rune_instance"], self, source_slot_ui)
	
	# Handle slot type drop
	elif data.has("slot_instance"):
		slot_type_dropped.emit(data["slot_instance"], self, source_slot_ui)
