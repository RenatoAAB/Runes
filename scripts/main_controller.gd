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
@export var choice_area: ChoiceArea
@export var upgrade_area: UpgradeArea

# We need a PackedScene for the SlotUI to instantiate them dynamically
# You can assign this in Inspector, or we can try to load it if it exists.
@export var slot_scene: PackedScene

@export var grid_highlighter: GridHighlighter

# Default LabelSettings to style SlotUI tooltips
@export var default_tooltip_label_settings: LabelSettings

# Map to keep track of UI instances
var grid_ui_slots: Dictionary = {} # Vector2i -> SlotUI
var inventory_ui_slots: Array[SlotUI] = []

## Reference to live stats display during battle
var _stats_display: StatsDisplay = null

func _ready() -> void:
	# Wait for managers to be ready
	# await get_tree().process_frame
	
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
		game_manager.rune_selection_requested.connect(_on_rune_selection_requested)
		game_manager.upgrade_requested.connect(_on_upgrade_requested)
		game_manager.phase_changed.connect(_on_phase_changed)
		# Force initial update in case level started before we connected
		_on_level_started(game_manager.current_level, game_manager.current_target_score)
	
	if grid_highlighter:
		grid_highlighter.request_multi_effect_highlight.connect(_on_request_multi_effect_highlight)
		grid_highlighter.request_condition_highlight.connect(_on_request_condition_highlight)
	
	if upgrade_area:
		upgrade_area.upgrade_confirmed.connect(_on_upgrade_confirmed)
		# Connect the input slot drop signal so MainController can handle drops onto it
		if upgrade_area.input_slot:
			upgrade_area.input_slot.rune_dropped.connect(_on_rune_dropped)

	# Configure TooltipManager if it exists
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and default_tooltip_label_settings:
		tooltip_manager.label_settings = default_tooltip_label_settings
		# RichTextLabel doesn't support label_settings directly, so we rely on TooltipManager to handle it.

## Handles multi-effect highlight requests from GridHighlighter.
## effect_indices is an array of effect indices that target this slot.
func _on_request_multi_effect_highlight(coord: Vector2i, effect_indices: Array) -> void:
	if grid_ui_slots.has(coord):
		grid_ui_slots[coord].set_effect_highlight(effect_indices)

## Handles condition highlight requests from GridHighlighter.
func _on_request_condition_highlight(coord: Vector2i, has_condition: bool) -> void:
	if grid_ui_slots.has(coord):
		grid_ui_slots[coord].set_condition_highlight(has_condition)

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
			# Apply default tooltip settings if available
			if default_tooltip_label_settings:
				slot_ui.tooltip_label_settings = default_tooltip_label_settings
			
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
		# Apply default tooltip settings if available
		if default_tooltip_label_settings:
			slot_ui.tooltip_label_settings = default_tooltip_label_settings
		
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
		slot_ui.update_slot_info(logic_slot)


func _on_rune_dropped(rune: RuneInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI) -> void:
	# Determine source and destination
	print("Rune Dropped. Source: %s, Target: %s" % [source_slot_ui, target_slot_ui])
	
	# Case 0: Drop from Choice Area (Selection)
	if source_slot_ui and choice_area and choice_area.is_choice_slot(source_slot_ui):
		print("Drop from Choice Area detected.")
		# Must drop into Inventory to select
		if target_slot_ui.inventory_index != -1:
			print("Dropped into Inventory. Selecting reward.")
			game_manager.select_rune_reward(rune.data)
			choice_area.hide_choices()
		else:
			print("Dropped outside inventory (Index: %d). Ignoring." % target_slot_ui.inventory_index)
		return

	# Case 1: Drop into Upgrade Input
	if upgrade_area and upgrade_area.is_upgrade_input_slot(target_slot_ui):
		# Try to place the rune. The UpgradeArea checks if it's a valid upgradeable rune.
		# This works for both Inventory and Grid runes since GameManager populates the valid list with both.
		if upgrade_area.try_place_rune(rune):
			pass 
		return

	# Case 2: Drop on Grid
	if target_slot_ui.grid_coord != Vector2i(-1, -1):
		if inventory_manager.runes.has(rune):
			# Move from Inventory -> Grid
			if grid_manager.place_rune(rune.data, target_slot_ui.grid_coord):
				inventory_manager.remove_rune(rune)
				# If it was in upgrade slot, clear it
				if upgrade_area and upgrade_area.current_rune_in_input == rune:
					upgrade_area._clear_input()
		else:
			# Move from Grid -> Grid (Swap/Move)
			var source_coord = _find_rune_coord(rune)
			if source_coord != Vector2i(-1, -1):
				grid_manager.move_rune(source_coord, target_slot_ui.grid_coord)

	# Case 3: Drop on Inventory (Unequip)
	elif target_slot_ui.inventory_index != -1:
		# Move Grid -> Inventory
		var source_coord = _find_rune_coord(rune)
		if source_coord != Vector2i(-1, -1):
			# Remove from grid
			var slot = grid_manager.get_slot(source_coord)
			slot.remove_rune()
			grid_manager.slot_changed.emit(source_coord)
			inventory_manager.add_rune(rune)
		
		# If dropped from Upgrade Input back to Inventory (Cancel Upgrade)
		if source_slot_ui and upgrade_area and upgrade_area.is_upgrade_input_slot(source_slot_ui):
			upgrade_area._clear_input()

# --- Signal Handlers ---

func _on_rune_selection_requested(options: Array[RuneData]) -> void:
	print("chegou o signal aqui")
	if choice_area:
		choice_area.show_choices(options)

func _on_upgrade_requested(runes: Array[RuneInstance]) -> void:
	if upgrade_area:
		upgrade_area.show_upgrade_ui(runes)

func _on_upgrade_confirmed(rune: RuneInstance) -> void:
	game_manager.confirm_upgrade(rune)
	
	# Force refresh of all UI slots to reflect the data change (new texture/stats)
	_on_inventory_updated()
	for coord in grid_ui_slots:
		_on_grid_slot_changed(coord)
		
	if upgrade_area:
		upgrade_area.hide_upgrade_ui()

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


func _on_phase_changed(new_phase: GameEnums.GamePhase) -> void:
	match new_phase:
		GameEnums.GamePhase.BATTLE:
			# Create stats display for battle
			_create_stats_display()
		GameEnums.GamePhase.RESOLUTION:
			# Remove stats display after battle
			_remove_stats_display()
		_:
			pass


func _create_stats_display() -> void:
	if _stats_display:
		return  # Already exists
	
	var ui_parent = get_tree().get_first_node_in_group("ui_layer")
	if not ui_parent:
		ui_parent = self
	
	_stats_display = StatsDisplay.create_panel(ui_parent, Vector2(10, 270))


func _remove_stats_display() -> void:
	if _stats_display:
		_stats_display.queue_free()
		_stats_display = null
