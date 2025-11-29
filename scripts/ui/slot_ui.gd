class_name SlotUI
extends PanelContainer

## Visual representation of a GridSlot or Inventory Slot.
## Handles the Drop part of Drag & Drop.

signal rune_dropped(source_rune: RuneInstance, target_slot_ui: SlotUI)

# If part of the grid, this will be set.
var grid_coord: Vector2i = Vector2i(-1, -1)
# If part of the inventory, this might be the index.
var inventory_index: int = -1

var rune_ui: RuneUI
var highlight_rect: ColorRect
var buff_rect: ColorRect

var current_slot_data: GridSlot

@export var tooltip_label_settings: LabelSettings

func _ready() -> void:
	# Create buff overlay (persistent state)
	buff_rect = ColorRect.new()
	buff_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	buff_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buff_rect.color = Color(0, 0, 0, 0)
	add_child(buff_rect)

	# Create highlight overlay (preview/interaction)
	highlight_rect = ColorRect.new()
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.color = Color(0, 0, 0, 0) # Transparent by default
	add_child(highlight_rect)
	
	# Ensure order: Background -> Buff -> Highlight -> Rune
	move_child(buff_rect, 0)
	move_child(highlight_rect, 1)
	
	mouse_entered.connect(self._on_mouse_entered)
	mouse_exited.connect(self._on_mouse_exited)

func set_highlight(color: Color) -> void:
	if highlight_rect:
		highlight_rect.color = color

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
	rune_dropped.emit(data["rune_instance"], self)
