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
@export var money_label: Label

# Shop references
var _shop_manager: ShopManager = null
var _shop_ui: ShopUI = null

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
		game_manager.phase_changed.connect(_on_phase_changed)
		game_manager.shop_phase_started.connect(_on_shop_phase_started)
		game_manager.free_pick_granted.connect(_on_free_pick_granted)
		# Force initial update in case level started before we connected
		_on_level_started(game_manager.current_level, game_manager.current_target_score)
	
	if grid_highlighter:
		grid_highlighter.request_multi_effect_highlight.connect(_on_request_multi_effect_highlight)
		grid_highlighter.request_condition_highlight.connect(_on_request_condition_highlight)
	
	# Connect to EventBus for economy updates
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("economy_transaction"):
		event_bus.economy_transaction.connect(_on_economy_changed)
	
	# Initialize money display
	_update_money_display()

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

	# Case 1: Drop on Grid
	if target_slot_ui.grid_coord != Vector2i(-1, -1):
		if inventory_manager.runes.has(rune):
			# Move from Inventory -> Grid
			if grid_manager.place_rune(rune.data, target_slot_ui.grid_coord):
				inventory_manager.remove_rune(rune)
		else:
			# Move from Grid -> Grid (Swap/Move)
			var source_coord = _find_rune_coord(rune)
			if source_coord != Vector2i(-1, -1):
				grid_manager.move_rune(source_coord, target_slot_ui.grid_coord)

	# Case 2: Drop on Inventory (Unequip)
	elif target_slot_ui.inventory_index != -1:
		# Move Grid -> Inventory
		var source_coord = _find_rune_coord(rune)
		if source_coord != Vector2i(-1, -1):
			# Remove from grid
			var slot = grid_manager.get_slot(source_coord)
			slot.remove_rune()
			grid_manager.slot_changed.emit(source_coord)
			inventory_manager.add_rune(rune)

# --- Legacy handlers removed - now handled by Shop ---

func _on_upgrade_confirmed(rune: RuneInstance) -> void:
	game_manager.confirm_upgrade(rune)
	
	# Force refresh of all UI slots to reflect the data change (new texture/stats)
	_on_inventory_updated()
	for coord in grid_ui_slots:
		_on_grid_slot_changed(coord)

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


func _on_economy_changed(_event) -> void:
	_update_money_display()


func _update_money_display() -> void:
	if money_label:
		var stats = get_node_or_null("/root/Stats")
		var money = stats.get_money() if stats else 0
		money_label.text = "$%d" % money


func _on_level_started(level: int, target: int) -> void:
	if level_label:
		level_label.text = "Level: %d (Target: %d)" % [level, target]


func _on_phase_changed(new_phase: GameEnums.GamePhase) -> void:
	match new_phase:
		GameEnums.GamePhase.BATTLE:
			# Create stats display for battle
			_create_stats_display()
			# Hide shop during battle
			_hide_shop()
		GameEnums.GamePhase.RESOLUTION:
			# Remove stats display after battle
			_remove_stats_display()
		GameEnums.GamePhase.PLANNING:
			# Hide shop when planning starts
			_hide_shop()
		GameEnums.GamePhase.SHOP:
			# Shop is shown via shop_phase_started signal
			pass
		_:
			pass


func _on_shop_phase_started() -> void:
	_show_shop()


func _show_shop() -> void:
	# Hide the grid while in shop, but keep inventory visible
	if grid_container:
		grid_container.visible = false
	if inventory_container:
		inventory_container.visible = true
	
	# Create shop manager if needed
	if not _shop_manager:
		_shop_manager = ShopManager.new()
		_shop_manager.name = "ShopManager"
		add_child(_shop_manager)
	
	# Create shop UI if needed
	if not _shop_ui:
		_shop_ui = ShopUI.create_shop_ui()
		
		var ui_parent = get_tree().get_first_node_in_group("ui_layer")
		if not ui_parent:
			ui_parent = self
		ui_parent.add_child(_shop_ui)
		
		# Connect shop signals
		_shop_ui.rune_purchased.connect(_on_shop_rune_purchased)
		_shop_ui.slot_purchased.connect(_on_shop_slot_purchased)
		_shop_ui.upgrade_completed.connect(_on_shop_upgrade_completed)
		_shop_ui.view_panel_requested.connect(_on_view_panel_requested)
		
		# Initialize with shop manager
		var level = game_manager.current_level if game_manager else 1
		_shop_ui.initialize(_shop_manager, level)
	else:
		# Refresh shop for new level
		var level = game_manager.current_level if game_manager else 1
		_shop_manager.refresh_shop(level)
	
	_shop_ui.visible = true
	_is_panel_view = false
	
	# Add "Continue" button to proceed to next level
	_add_shop_continue_button()


func _hide_shop() -> void:
	if _shop_ui:
		_shop_ui.visible = false
	_hide_panel_view()
	_remove_shop_continue_button()
	_remove_back_to_shop_button()
	_remove_panel_battle_button()
	
	# Show the game panel again
	_set_game_panel_visible(true)


func _remove_back_to_shop_button() -> void:
	if _back_to_shop_button:
		_back_to_shop_button.queue_free()
		_back_to_shop_button = null


## Toggle visibility of game panel elements (grid, inventory, score, etc.)
## This is called when entering/exiting shop phase entirely.
func _set_game_panel_visible(is_visible: bool) -> void:
	if grid_container:
		grid_container.visible = is_visible
	if inventory_container:
		inventory_container.visible = is_visible


var _shop_continue_button: Button = null

func _add_shop_continue_button() -> void:
	if _shop_continue_button:
		return
	
	_shop_continue_button = Button.new()
	_shop_continue_button.name = "ShopContinueButton"
	_shop_continue_button.text = "Go to Panel →"
	_shop_continue_button.custom_minimum_size = Vector2(150, 40)
	_shop_continue_button.pressed.connect(_on_go_to_panel_pressed)
	
	var ui_parent = get_tree().get_first_node_in_group("ui_layer")
	if ui_parent:
		ui_parent.add_child(_shop_continue_button)
		# Position at bottom right
		_shop_continue_button.position = Vector2(
			get_viewport().size.x - 170,
			get_viewport().size.y - 60
		)


func _remove_shop_continue_button() -> void:
	if _shop_continue_button:
		_shop_continue_button.queue_free()
		_shop_continue_button = null


func _on_go_to_panel_pressed() -> void:
	# Just switch to panel view (don't finish shop phase yet)
	_toggle_panel_view()


func _on_shop_rune_purchased(rune: RuneInstance) -> void:
	if inventory_manager:
		inventory_manager.add_rune(rune)
		_on_inventory_updated()


func _on_shop_slot_purchased(slot: SlotInstance) -> void:
	# For now, slots go to a "slot inventory" or player can place them
	# We'll add them to a pending slots list
	print("Slot purchased: %s (place it on the grid)" % slot.data.slot_name)
	# TODO: Add slot inventory or allow placing immediately


func _on_shop_upgrade_completed(new_rune: RuneInstance) -> void:
	if inventory_manager:
		inventory_manager.add_rune(new_rune)
		_on_inventory_updated()


func _on_free_pick_granted(count: int) -> void:
	if _shop_manager:
		_shop_manager.grant_free_pick(count)


# --- View Toggle: Shop vs Panel ---
var _is_panel_view: bool = false
var _back_to_shop_button: Button = null
var _panel_battle_button: Button = null

func _on_view_panel_requested() -> void:
	_toggle_panel_view()


func _toggle_panel_view() -> void:
	_is_panel_view = not _is_panel_view
	
	if _is_panel_view:
		# Hide shop, show real panel (grid + inventory)
		if _shop_ui:
			_shop_ui.visible = false
		_remove_shop_continue_button()
		_show_panel_view()
	else:
		# Hide panel, show shop
		_hide_panel_view()
		if _shop_ui:
			_shop_ui.visible = true
		_add_shop_continue_button()


func _show_panel_view() -> void:
	# Show grid and inventory (the actual game panel)
	if grid_container:
		grid_container.visible = true
	if inventory_container:
		inventory_container.visible = true
	
	var ui_parent = get_tree().get_first_node_in_group("ui_layer")
	if not ui_parent:
		ui_parent = self
	
	# Add "Go to Shop" button
	if not _back_to_shop_button:
		_back_to_shop_button = Button.new()
		_back_to_shop_button.name = "BackToShopButton"
		_back_to_shop_button.text = "← Go to Shop"
		_back_to_shop_button.custom_minimum_size = Vector2(150, 40)
		_back_to_shop_button.pressed.connect(_toggle_panel_view)
		ui_parent.add_child(_back_to_shop_button)
		_back_to_shop_button.position = Vector2(20, 20)
	
	_back_to_shop_button.visible = true
	
	# Add "Battle!" button
	if not _panel_battle_button:
		_panel_battle_button = Button.new()
		_panel_battle_button.name = "PanelBattleButton"
		_panel_battle_button.text = "⚔ Battle!"
		_panel_battle_button.custom_minimum_size = Vector2(150, 40)
		_panel_battle_button.pressed.connect(_on_panel_battle_pressed)
		ui_parent.add_child(_panel_battle_button)
		# Position at bottom right
		_panel_battle_button.position = Vector2(
			get_viewport().size.x - 170,
			get_viewport().size.y - 60
		)
	
	_panel_battle_button.visible = true


func _on_panel_battle_pressed() -> void:
	# Finish shop phase and start battle
	if game_manager:
		game_manager.finish_shop_phase()
		# Hide panel UI elements
		_hide_panel_view()
		_remove_panel_battle_button()
		_remove_back_to_shop_button()
		# Start the battle
		game_manager.start_battle()


func _remove_panel_battle_button() -> void:
	if _panel_battle_button:
		_panel_battle_button.queue_free()
		_panel_battle_button = null


func _hide_panel_view() -> void:
	# Hide grid when going back to shop (inventory stays visible)
	if grid_container:
		grid_container.visible = false
	
	# Hide buttons
	if _back_to_shop_button:
		_back_to_shop_button.visible = false
	if _panel_battle_button:
		_panel_battle_button.visible = false


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
