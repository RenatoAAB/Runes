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

func _ready() -> void:
	# Create highlight overlay
	highlight_rect = ColorRect.new()
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_rect.color = Color(0, 0, 0, 0) # Transparent by default
	add_child(highlight_rect)
	# Ensure highlight is behind the rune but in front of background
	move_child(highlight_rect, 0)

func set_highlight(color: Color) -> void:
	if highlight_rect:
		highlight_rect.color = color

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
		rune_ui.custom_minimum_size = Vector2(64, 64) # Example size
		add_child(rune_ui)
		rune_ui.setup(rune)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Check if the data contains a rune instance
	return typeof(data) == TYPE_DICTIONARY and data.has("rune_instance")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Emit signal to let the controller handle the logic
	rune_dropped.emit(data["rune_instance"], self)
