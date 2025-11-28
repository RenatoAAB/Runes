class_name MainController
extends Node

## The "Glue" script that connects Logic to UI.
## Attaches to the Root Node of the Main Scene.

@export_group("Managers")
@export var game_manager: GameManager
@export var grid_manager: GridManager
@export var inventory_manager: InventoryManager
@export var reader: Reader

@export_group("UI Containers")
@export var grid_container: Control # GridContainer
@export var inventory_container: Control # HBoxContainer or GridContainer
@export var score_label: Label
@export var level_label: Label

# We need a PackedScene for the SlotUI to instantiate them dynamically
# You can assign this in Inspector, or we can try to load it if it exists.
@export var slot_scene: PackedScene

@export var grid_highlighter: GridHighlighter

# Map to keep track of UI instances
var grid_ui_slots: Dictionary = {} # Vector2i -> SlotUI
var inventory_ui_slots: Array[SlotUI] = []

func _ready() -> void:
	# Wait for managers to be ready
	await get_tree().process_frame
	
	_generate_grid_ui()
	_generate_inventory_ui()
	
	# Connect Signals
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)
		# Force initial update in case items were added before we connected
		_on_inventory_updated()
	
	if grid_manager:
		grid_manager.slot_changed.connect(_on_grid_slot_changed)
		
	if reader:
		reader.step_started.connect(_on_reader_step)
		reader.step_completed.connect(_on_reader_step_done)
		reader.score_updated.connect(_on_score_updated)
		
	if game_manager:
		game_manager.level_started.connect(_on_level_started)
		# Force initial update in case level started before we connected
		_on_level_started(game_manager.current_level, game_manager.current_target_score)
	
	if grid_highlighter:
		grid_highlighter.request_highlight.connect(_on_request_highlight)

func _on_request_highlight(coord: Vector2i, color: Color) -> void:
	if coord == Vector2i(-1, -1):
		# Clear all
		for slot in grid_ui_slots.values():
			slot.set_highlight(Color(0, 0, 0, 0))
	elif grid_ui_slots.has(coord):
		grid_ui_slots[coord].set_highlight(color)

# --- UI Generation ---

func _generate_grid_ui() -> void:
	# Clear existing children if any (useful for restarts)
	for child in grid_container.get_children():
		child.queue_free()
	grid_ui_slots.clear()
	
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var slot_ui = _create_slot_ui()
			grid_container.add_child(slot_ui)
			
			slot_ui.grid_coord = Vector2i(x, y)
			slot_ui.rune_dropped.connect(_on_rune_dropped)
			
			grid_ui_slots[Vector2i(x, y)] = slot_ui

func _generate_inventory_ui() -> void:
	for child in inventory_container.get_children():
		child.queue_free()
	inventory_ui_slots.clear()
	
	# Create fixed number of inventory slots
	for i in range(inventory_manager.max_slots):
		var slot_ui = _create_slot_ui()
		inventory_container.add_child(slot_ui)
		
		slot_ui.inventory_index = i
		slot_ui.rune_dropped.connect(_on_rune_dropped)
		
		inventory_ui_slots.append(slot_ui)

func _create_slot_ui() -> SlotUI:
	if slot_scene:
		return slot_scene.instantiate() as SlotUI
	else:
		# Fallback if no scene assigned: Create programmatically
		var slot = SlotUI.new()
		slot.custom_minimum_size = Vector2(64, 64)
		# Add a background style for visibility
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		slot.add_theme_stylebox_override("panel", style)
		return slot

# --- Signal Handlers ---

func _on_inventory_updated() -> void:
	# Refresh all inventory slots
	for i in range(inventory_ui_slots.size()):
		var slot_ui = inventory_ui_slots[i]
		var rune = inventory_manager.get_rune_at(i)
		slot_ui.set_rune(rune)

func _on_grid_slot_changed(coord: Vector2i) -> void:
	if grid_ui_slots.has(coord):
		var slot_ui = grid_ui_slots[coord]
		var logic_slot = grid_manager.get_slot(coord)
		slot_ui.set_rune(logic_slot.rune)

func _on_rune_dropped(rune: RuneInstance, target_slot_ui: SlotUI) -> void:
	# Determine source and destination
	# This is a simplified logic. In a full game, we'd handle swapping, etc.
	
	# 1. If dropped on Grid
	if target_slot_ui.grid_coord != Vector2i(-1, -1):
		# Check if we are moving from Inventory or Grid
		# For now, let's assume we are moving FROM inventory (since we don't track source coord in drag data yet)
		# Wait, RuneUI._get_drag_data passes "source_ui".
		
		# We need to find where the rune came from.
		# But RuneInstance is unique. We can check if it's in inventory.
		
		if inventory_manager.runes.has(rune):
			# Move from Inventory -> Grid
			if grid_manager.place_rune(rune.data, target_slot_ui.grid_coord):
				inventory_manager.remove_rune(rune)
		else:
			# Move from Grid -> Grid (Swap/Move)
			# We need to find the source coordinate.
			var source_coord = _find_rune_coord(rune)
			if source_coord != Vector2i(-1, -1):
				grid_manager.move_rune(source_coord, target_slot_ui.grid_coord)

	# 2. If dropped on Inventory (Optional: Unequip)
	elif target_slot_ui.inventory_index != -1:
		# Move Grid -> Inventory
		var source_coord = _find_rune_coord(rune)
		if source_coord != Vector2i(-1, -1):
			# Remove from grid
			var slot = grid_manager.get_slot(source_coord)
			slot.remove_rune()
			grid_manager.slot_changed.emit(source_coord) # Force update
			
			# Add to inventory
			inventory_manager.add_rune(rune)

func _find_rune_coord(rune: RuneInstance) -> Vector2i:
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var coord = Vector2i(x, y)
			var slot = grid_manager.get_slot(coord)
			if slot.rune == rune:
				return coord
	return Vector2i(-1, -1)

# --- Visual Feedback ---

func _on_reader_step(coord: Vector2i) -> void:
	if grid_ui_slots.has(coord):
		var slot_ui = grid_ui_slots[coord]
		slot_ui.set_highlight(Color(1, 1, 0, 0.5)) # Yellow highlight for reader

func _on_reader_step_done(coord: Vector2i) -> void:
	if grid_ui_slots.has(coord):
		var slot_ui = grid_ui_slots[coord]
		slot_ui.set_highlight(Color(0, 0, 0, 0)) # Clear

func _on_score_updated(new_total: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_total

func _on_level_started(level: int, target: int) -> void:
	if level_label:
		level_label.text = "Level: %d (Target: %d)" % [level, target]
