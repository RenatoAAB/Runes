class_name SlotUI
extends PanelContainer

## Visual representation of a GridSlot or Inventory Slot.
## Handles the Drop part of Drag & Drop.
## Supports multi-effect visualization when multiple effects target this slot.

signal rune_dropped(source_rune: RuneInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI)

# If part of the grid, this will be set.
var grid_coord: Vector2i = Vector2i(-1, -1)
# If part of the inventory, this might be the index.
var inventory_index: int = -1

var rune_ui: RuneUI
var multi_effect_overlay: MultiEffectOverlay
var buff_rect: ColorRect

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
	# Update buff visual based on state
	if slot and not slot.active_states.is_empty():
		# Check for specific states or just generic "buffed"
		# For now, if any state exists, we show a color.
		# Ideally, we'd map state_id to color.
		# Let's use a generic Blue for now as requested.
		set_buff_highlight(Color(0.2, 0.2, 1.0, 0.3))
	else:
		set_buff_highlight(Color(0, 0, 0, 0))

func _on_mouse_entered() -> void:
	if not current_slot_data or current_slot_data.active_states.is_empty():
		return
		
	var text = "[color=cyan]Slot Effects:[/color]\n"
	for state_id in current_slot_data.active_states:
		var data = current_slot_data.active_states[state_id]
		text += "- %s (%d turns)" % [state_id.capitalize(), data["duration"]]
		if data.get("score_bonus", 0) != 0:
			text += "\n  Bonus: +%d Score" % data["score_bonus"]
		if data.get("activation_bonus", 0) != 0:
			text += "\n  Bonus: +%d Activations" % data["activation_bonus"]
			
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.set_slot_tooltip(text)

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

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Check if the data contains a rune instance
	return typeof(data) == TYPE_DICTIONARY and data.has("rune_instance")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Emit signal to let the controller handle the logic
	var source_ui = data.get("source_ui")
	# source_ui is likely a RuneUI. We need its parent SlotUI.
	var source_slot = null
	if source_ui and source_ui.get_parent() is SlotUI:
		source_slot = source_ui.get_parent()
		
	rune_dropped.emit(data["rune_instance"], self, source_slot)
