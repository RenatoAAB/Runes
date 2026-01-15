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
@export var other_inventory_container: Control # For relics, etc.
@export var relic_slots_container: Control # Container for 3 relic slots per panel
@export var score_label: Label
@export var level_label: Label
@export var money_label: Label
@export var panel_label: Label  # Shows current panel (e.g., "Panel 1/3")
@export var enter_shop_button: Button
@export var battle_button: Button
@export var previous_panel_button: Button
@export var next_panel_button: Button

# Shop references (now from scene)
@export_group("Shop")
@export var shop_ui: ShopUI
var _shop_manager: ShopManager = null

# Panel system
var _panel_manager: PanelManager = null
var _extra_inventory: ExtraInventoryManager = null
var _relic_slot_uis: Array[RelicSlotUI] = []
var _current_panel_index: int = 0
var _bound_grid_manager: GridManager = null
var _bound_reader: Reader = null

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
	
	# Initialize panel system
	_initialize_panel_system()
	
	_generate_grid_ui()
	_generate_inventory_ui()
	_generate_relic_slots()
	
	# Connect Signals
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)
		# Force initial update in case items were added before we connected
		_on_inventory_updated()
	
	if grid_manager and not grid_manager.slot_changed.is_connected(_on_grid_slot_changed):
		grid_manager.slot_changed.connect(_on_grid_slot_changed)
		
	if reader:
		if not reader.step_started.is_connected(_on_reader_step):
			reader.step_started.connect(_on_reader_step)
		if not reader.step_completed.is_connected(_on_reader_step_done):
			reader.step_completed.connect(_on_reader_step_done)
		if not reader.score_updated.is_connected(_on_score_updated):
			reader.score_updated.connect(_on_score_updated)
		
	if game_manager:
		game_manager.level_started.connect(_on_level_started)
		game_manager.phase_changed.connect(_on_phase_changed)
		game_manager.free_pick_granted.connect(_on_free_pick_granted)
		game_manager.game_lost.connect(_on_game_lost)
		# Force initial update in case level started before we connected
		_on_level_started(game_manager.current_level, game_manager.current_target_score)
	
	if grid_highlighter:
		grid_highlighter.request_multi_effect_highlight.connect(_on_request_multi_effect_highlight)
		grid_highlighter.request_condition_highlight.connect(_on_request_condition_highlight)
	
	# Connect Enter Shop button from GameUI
	if enter_shop_button and not enter_shop_button.pressed.is_connected(_on_enter_shop_pressed):
		enter_shop_button.pressed.connect(_on_enter_shop_pressed)
		# Initially hide it (will be shown during PLANNING phase)
		enter_shop_button.visible = false
	
	# Connect panel navigation buttons
	if previous_panel_button and not previous_panel_button.pressed.is_connected(_on_previous_panel_pressed):
		previous_panel_button.pressed.connect(_on_previous_panel_pressed)
	if next_panel_button and not next_panel_button.pressed.is_connected(_on_next_panel_pressed):
		next_panel_button.pressed.connect(_on_next_panel_pressed)
	
	# Connect to EventBus for economy updates
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("economy_transaction"):
		event_bus.economy_transaction.connect(_on_economy_changed)
	
	# Initialize money display
	_update_money_display()
	_update_panel_navigation()

	# Configure TooltipManager if it exists
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager and default_tooltip_label_settings:
		tooltip_manager.label_settings = default_tooltip_label_settings
		# RichTextLabel doesn't support label_settings directly, so we rely on TooltipManager to handle it.


## Initialize the panel management system
func _initialize_panel_system() -> void:
	# Create PanelManager
	_panel_manager = PanelManager.new()
	_panel_manager.name = "PanelManager"
	add_child(_panel_manager)
	_panel_manager.add_to_group("panel_manager")
	_panel_manager.initialize_default()
	# Instantiate grids/readers for unlocked panels at game start
	_panel_manager.setup_all_panels(self)
	_bind_active_panel_nodes()
	
	# Connect panel manager signals
	_panel_manager.panel_switched.connect(_on_panel_switched)
	_panel_manager.panel_unlocked.connect(_on_panel_unlocked)
	
	# Create ExtraInventoryManager for relics, modifiers, pieces
	_extra_inventory = ExtraInventoryManager.new()
	_extra_inventory.name = "ExtraInventory"
	add_child(_extra_inventory)
	
	# Connect ExtraInventory signals for UI updates
	_extra_inventory.inventory_changed.connect(_on_extra_inventory_updated)
	_update_other_inventory_display()


## Bind grid/reader references and signals to the currently active panel
func _bind_active_panel_nodes() -> void:
	if not _panel_manager:
		return
	var panel = _panel_manager.get_panel(_current_panel_index)
	_bind_panel_nodes(panel)


func _bind_panel_nodes(panel: PanelInstance) -> void:
	_disconnect_panel_nodes()
	if not panel:
		grid_manager = null
		reader = null
		return
	
	grid_manager = panel.grid_manager
	reader = panel.reader
	
	if grid_manager and not grid_manager.slot_changed.is_connected(_on_grid_slot_changed):
		grid_manager.slot_changed.connect(_on_grid_slot_changed)
	if reader:
		if not reader.step_started.is_connected(_on_reader_step):
			reader.step_started.connect(_on_reader_step)
		if not reader.step_completed.is_connected(_on_reader_step_done):
			reader.step_completed.connect(_on_reader_step_done)
		if not reader.score_updated.is_connected(_on_score_updated):
			reader.score_updated.connect(_on_score_updated)
	
	_bound_grid_manager = grid_manager
	_bound_reader = reader


func _disconnect_panel_nodes() -> void:
	if _bound_grid_manager and _bound_grid_manager.slot_changed.is_connected(_on_grid_slot_changed):
		_bound_grid_manager.slot_changed.disconnect(_on_grid_slot_changed)
	if _bound_reader:
		if _bound_reader.step_started.is_connected(_on_reader_step):
			_bound_reader.step_started.disconnect(_on_reader_step)
		if _bound_reader.step_completed.is_connected(_on_reader_step_done):
			_bound_reader.step_completed.disconnect(_on_reader_step_done)
		if _bound_reader.score_updated.is_connected(_on_score_updated):
			_bound_reader.score_updated.disconnect(_on_score_updated)
	_bound_grid_manager = null
	_bound_reader = null


## Generate relic slots UI (3 slots per panel)
func _generate_relic_slots() -> void:
	if not relic_slots_container:
		return
	
	# Clear existing
	for child in relic_slots_container.get_children():
		child.queue_free()
	_relic_slot_uis.clear()
	
	# Create 3 relic slots
	for i in range(3):
		var relic_slot = RelicSlotUI.new()
		relic_slot.slot_index = i
		relic_slot.panel_index = _current_panel_index
		relic_slot.relic_dropped.connect(_on_relic_dropped)
		relic_slot.relic_clicked.connect(_on_relic_clicked)
		relic_slots_container.add_child(relic_slot)
		_relic_slot_uis.append(relic_slot)
	
	_update_relic_slots_display()


## Update relic slots to show current panel's relics
func _update_relic_slots_display() -> void:
	if not _panel_manager:
		return
	
	var panel = _panel_manager.get_panel(_current_panel_index)
	if not panel:
		return
	
	for i in range(_relic_slot_uis.size()):
		var slot_ui = _relic_slot_uis[i]
		slot_ui.panel_index = _current_panel_index
		
		# Set relic if panel has one at this index
		if i < panel.attached_relics.size():
			slot_ui.set_relic(panel.attached_relics[i])
		else:
			slot_ui.set_relic(null)


## Handle panel navigation
func _on_previous_panel_pressed() -> void:
	if not _panel_manager:
		return
	
	var unlocked = _panel_manager.get_unlocked_panels()
	var current_idx = 0
	for i in range(unlocked.size()):
		if unlocked[i].panel_index == _current_panel_index:
			current_idx = i
			break
	
	if current_idx > 0:
		_current_panel_index = unlocked[current_idx - 1].panel_index
		_panel_manager.switch_to_panel(_current_panel_index)


func _on_next_panel_pressed() -> void:
	if not _panel_manager:
		return
	
	var unlocked = _panel_manager.get_unlocked_panels()
	var current_idx = 0
	for i in range(unlocked.size()):
		if unlocked[i].panel_index == _current_panel_index:
			current_idx = i
			break
	
	if current_idx < unlocked.size() - 1:
		_current_panel_index = unlocked[current_idx + 1].panel_index
		_panel_manager.switch_to_panel(_current_panel_index)


func _on_panel_switched(_from_index: int, to_index: int) -> void:
	_current_panel_index = to_index
	_bind_active_panel_nodes()
	_update_panel_navigation()
	_update_relic_slots_display()
	_generate_grid_ui()


func _on_panel_unlocked(_panel: PanelInstance) -> void:
	_update_panel_navigation()


func _update_panel_navigation() -> void:
	if not _panel_manager:
		return
	
	var unlocked = _panel_manager.get_unlocked_panels()
	var total = _panel_manager.panels.size()
	var unlocked_count = unlocked.size()
	
	# Update panel label
	if panel_label:
		panel_label.text = "Panel %d/%d" % [_current_panel_index + 1, unlocked_count]
	
	# Find current position in unlocked panels
	var current_idx = 0
	for i in range(unlocked.size()):
		if unlocked[i].panel_index == _current_panel_index:
			current_idx = i
			break
	
	# Update button states
	if previous_panel_button:
		previous_panel_button.disabled = current_idx <= 0
	if next_panel_button:
		next_panel_button.disabled = current_idx >= unlocked_count - 1


## Handle relic dropped on a slot
func _on_relic_dropped(relic: RelicInstance, target_slot_ui: RelicSlotUI, source_slot_ui: RelicSlotUI) -> void:
	if not _panel_manager or not _extra_inventory:
		return
	
	var target_panel = _panel_manager.get_panel(target_slot_ui.panel_index)
	if not target_panel:
		return
	
	# If relic comes from another relic slot, detach from that panel first
	if source_slot_ui:
		var source_panel = _panel_manager.get_panel(source_slot_ui.panel_index)
		if source_panel:
			source_panel.detach_relic(relic)
		relic.detach_from_panel()
		source_slot_ui.clear_relic()
	elif relic.is_attached():
		# Relic is attached to a panel but dragged from somewhere else
		var source_panel = _panel_manager.get_panel(relic.attached_panel_index)
		if source_panel:
			source_panel.detach_relic(relic)
		relic.detach_from_panel()
	else:
		# Remove from extra inventory since it's coming from there
		_extra_inventory.remove_relic(relic)
	
	# Try to attach relic to target panel
	if target_panel.attach_relic(relic):
		relic.attach_to_panel(target_slot_ui.panel_index)
		target_slot_ui.set_relic(relic)
	
	_update_relic_slots_display()
	_update_other_inventory_display()


func _on_relic_clicked(relic: RelicInstance) -> void:
	# Click on attached relic detaches it and returns to extra inventory
	if relic and relic.is_attached():
		var panel = _panel_manager.get_panel(relic.attached_panel_index)
		if panel:
			panel.detach_relic(relic)
			relic.detach_from_panel()
			# Add back to extra inventory
			if _extra_inventory:
				_extra_inventory.add_relic(relic)
			_update_relic_slots_display()
			_update_other_inventory_display()

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
	
	# Get current panel to determine which slots are unlocked
	var panel: PanelInstance = null
	if _panel_manager:
		panel = _panel_manager.get_panel(_current_panel_index)
	
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var coord = Vector2i(x, y)
			var slot_ui = _create_slot_ui()
			grid_container.add_child(slot_ui)
			
			# Apply default tooltip settings if available
			if default_tooltip_label_settings:
				slot_ui.tooltip_label_settings = default_tooltip_label_settings
			
			slot_ui.grid_coord = coord
			
			# Set locked/unlocked state based on panel
			if panel:
				var is_unlocked = panel.is_slot_unlocked(coord)
				slot_ui.set_locked_state(is_unlocked)
			
			# Connect signals
			slot_ui.rune_dropped.connect(_on_rune_dropped)
			slot_ui.modifier_dropped.connect(_on_modifier_dropped)
			slot_ui.piece_dropped.connect(_on_piece_dropped)
			
			grid_ui_slots[coord] = slot_ui

	_refresh_grid_ui_from_logic()


func _refresh_grid_ui_from_logic() -> void:
	if not _panel_manager:
		return
	var panel = _panel_manager.get_panel(_current_panel_index)
	if not panel or not panel.grid_manager:
		return

	for coord in grid_ui_slots.keys():
		var slot_ui = grid_ui_slots[coord]
		var logic_slot = panel.grid_manager.get_slot(coord)
		slot_ui.set_locked_state(panel.is_slot_unlocked(coord))
		if logic_slot:
			slot_ui.set_rune(logic_slot.rune)
			slot_ui.update_slot_info(logic_slot)
		else:
			slot_ui.set_rune(null)

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
		if inventory_manager.has_rune(rune):
			# Move from Inventory -> Grid (keep RuneInstance to preserve permanent buffs)
			if grid_manager.place_rune_instance(rune, target_slot_ui.grid_coord):
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


## Handle modifier dropped on a grid slot
func _on_modifier_dropped(modifier: SlotModifierData, target_slot_ui: SlotUI) -> void:
	if not modifier or not _panel_manager or not _extra_inventory:
		return
	
	var coord = target_slot_ui.grid_coord
	if coord == Vector2i(-1, -1):
		return
	
	var panel = _panel_manager.get_panel(_current_panel_index)
	if not panel or not panel.is_slot_unlocked(coord):
		print("Cannot apply modifier: slot is not unlocked")
		return
	
	# Get the GridSlot and apply the modifier
	var grid_slot = grid_manager.get_slot(coord) if grid_manager else null
	if grid_slot and grid_slot.slot:
		if grid_slot.slot.apply_modifier(modifier):
			# Remove from extra inventory
			_extra_inventory.remove_modifier(modifier)
			# Update visuals
			_on_grid_slot_changed(coord)
			_update_other_inventory_display()
			print("Modifier '%s' applied to slot at %s" % [modifier.display_name, coord])
		else:
			print("Failed to apply modifier '%s'" % modifier.display_name)


## Handle piece dropped on a locked grid slot
func _on_piece_dropped(piece: SlotPieceData, target_slot_ui: SlotUI) -> void:
	if not piece or not _panel_manager or not _extra_inventory:
		return
	
	var coord = target_slot_ui.grid_coord
	if coord == Vector2i(-1, -1):
		return
	
	var panel = _panel_manager.get_panel(_current_panel_index)
	if not panel:
		return
	
	# Check if piece can be placed (must be adjacent to existing slots)
	if not panel.can_place_piece(piece.shape, coord):
		print("Cannot place piece: invalid position")
		return
	
	# Unlock slots from the piece
	var unlocked_count = panel.unlock_slots_from_piece(piece.shape, coord)
	if unlocked_count > 0:
		# Remove piece from extra inventory
		var piece_instance = _extra_inventory.find_piece_by_data(piece)
		if piece_instance:
			_extra_inventory.remove_piece(piece_instance)
		
		# Regenerate grid UI to show newly unlocked slots
		_generate_grid_ui()
		_update_other_inventory_display()
		print("Piece '%s' placed at %s, unlocked %d slots" % [piece.display_name, coord, unlocked_count])
	else:
		print("No slots were unlocked from piece")


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
			# Hide enter shop button during battle
			if enter_shop_button:
				enter_shop_button.visible = false
		GameEnums.GamePhase.RESOLUTION:
			# Remove stats display after battle
			_remove_stats_display()
		GameEnums.GamePhase.PLANNING:
			# Hide shop view when planning starts (player can reopen it)
			_hide_shop()
			# Show enter shop button during planning
			if enter_shop_button:
				enter_shop_button.visible = true
		_:
			pass


## Called when the player loses the game - reset panels to initial 3x3 state
func _on_game_lost() -> void:
	if _panel_manager:
		_panel_manager.full_reset_all_panels()
		_current_panel_index = 0
		_generate_grid_ui()
		_generate_relic_slots()
		_update_panel_navigation()
	
	# Clear extra inventory (relics, modifiers, pieces)
	if _extra_inventory:
		_extra_inventory.clear_all()
		_update_other_inventory_display()


func _on_enter_shop_pressed() -> void:
	# Allow entering shop during PLANNING phase
	if game_manager and game_manager.current_phase == GameEnums.GamePhase.PLANNING:
		_show_shop()


func _show_shop() -> void:
	# Hide only the grid and battle-specific elements
	# Keep inventories and money visible!
	if grid_container:
		grid_container.visible = false
	
	# Hide battle/panel-specific elements
	if score_label:
		score_label.visible = false
	if level_label:
		level_label.visible = false
	if battle_button:
		battle_button.visible = false
	if previous_panel_button:
		previous_panel_button.visible = false
	if next_panel_button:
		next_panel_button.visible = false
	
	# Hide the EnterShop button while in shop
	if enter_shop_button:
		enter_shop_button.visible = false
	
	# Hide relic slots while in shop (they're panel-specific)
	if relic_slots_container:
		relic_slots_container.visible = false
	
	# Keep inventory containers visible
	if inventory_container:
		inventory_container.visible = true
	if other_inventory_container:
		other_inventory_container.visible = true
	
	# Keep money label visible
	if money_label:
		money_label.visible = true
	
	# Create shop manager if needed
	if not _shop_manager:
		_shop_manager = ShopManager.new()
		_shop_manager.name = "ShopManager"
		add_child(_shop_manager)
	
	# Use shop UI from scene (assigned via @export)
	if shop_ui:
		# Connect shop signals if not already connected
		if not shop_ui.rune_purchased.is_connected(_on_shop_rune_purchased):
			shop_ui.rune_purchased.connect(_on_shop_rune_purchased)
		if not shop_ui.piece_purchased.is_connected(_on_shop_piece_purchased):
			shop_ui.piece_purchased.connect(_on_shop_piece_purchased)
		if not shop_ui.modifier_purchased.is_connected(_on_shop_modifier_purchased):
			shop_ui.modifier_purchased.connect(_on_shop_modifier_purchased)
		if not shop_ui.relic_purchased.is_connected(_on_shop_relic_purchased):
			shop_ui.relic_purchased.connect(_on_shop_relic_purchased)
		if not shop_ui.upgrade_completed.is_connected(_on_shop_upgrade_completed):
			shop_ui.upgrade_completed.connect(_on_shop_upgrade_completed)
		if not shop_ui.view_panel_requested.is_connected(_on_view_panel_requested):
			shop_ui.view_panel_requested.connect(_on_view_panel_requested)
		
		# Initialize with shop manager
		var level = game_manager.current_level if game_manager else 1
		shop_ui.initialize(_shop_manager, level)
		shop_ui.visible = true
	else:
		push_warning("MainController: shop_ui not assigned in scene!")


func _hide_shop() -> void:
	if shop_ui:
		shop_ui.visible = false
	
	# Show the grid again
	if grid_container:
		grid_container.visible = true
	
	# Show battle/panel-specific elements
	if score_label:
		score_label.visible = true
	if level_label:
		level_label.visible = true
	if battle_button:
		battle_button.visible = true
	if previous_panel_button:
		previous_panel_button.visible = true
	if next_panel_button:
		next_panel_button.visible = true
	
	# Show the EnterShop button when in GameUI during PLANNING phase
	if enter_shop_button:
		var in_planning_phase = game_manager and game_manager.current_phase == GameEnums.GamePhase.PLANNING
		enter_shop_button.visible = in_planning_phase
	
	# Show relic slots again (they're panel-specific)
	if relic_slots_container:
		relic_slots_container.visible = true
	
	# Keep inventory containers visible (they're always visible)
	if inventory_container:
		inventory_container.visible = true
	if other_inventory_container:
		other_inventory_container.visible = true
	
	# Keep money label visible
	if money_label:
		money_label.visible = true


func _on_shop_rune_purchased(rune: RuneInstance) -> void:
	if inventory_manager:
		inventory_manager.add_rune(rune)
		_on_inventory_updated()


func _on_shop_piece_purchased(piece: SlotPieceInstance) -> void:
	# Slot pieces go to ExtraInventory for placement on panels
	if _extra_inventory:
		_extra_inventory.add_slot_piece(piece)
		print("Piece added to inventory: %s" % piece.data.display_name)
	else:
		push_warning("No ExtraInventory to store piece")


func _on_shop_modifier_purchased(modifier: SlotModifierData) -> void:
	# Modifiers go to ExtraInventory for application on slots
	if _extra_inventory:
		_extra_inventory.add_modifier(modifier)
		print("Modifier added to inventory: %s" % modifier.display_name)
	else:
		push_warning("No ExtraInventory to store modifier")


func _on_shop_relic_purchased(relic: RelicInstance) -> void:
	# Relics go to ExtraInventory for attachment to panels
	if _extra_inventory:
		_extra_inventory.add_relic(relic)
		print("Relic added to inventory: %s" % relic.data.display_name)
	else:
		push_warning("No ExtraInventory to store relic")


func _on_shop_upgrade_completed(new_rune: RuneInstance) -> void:
	if inventory_manager:
		inventory_manager.add_rune(new_rune)
		_on_inventory_updated()


func _on_free_pick_granted(count: int) -> void:
	if _shop_manager:
		_shop_manager.grant_free_pick(count)


# --- View Toggle: Shop vs Panel (using existing buttons) ---

func _on_view_panel_requested() -> void:
	# Called when "Manage Runes" button is pressed in ShopUI
	# Switch from ShopUI to GameUI (panel view)
	_hide_shop()
	
	# Show the EnterShop button so user can go back to shop
	if enter_shop_button:
		enter_shop_button.visible = true


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


# --- Extra Inventory (Pieces, Modifiers, Relics) Display ---

func _on_extra_inventory_updated() -> void:
	_update_other_inventory_display()


## Update OtherInventoryContainer to show items from ExtraInventory
func _update_other_inventory_display() -> void:
	if not other_inventory_container or not _extra_inventory:
		return
	
	var slots = other_inventory_container.get_children()
	
	# Collect all extra items
	var items: Array = []  # {type: "relic"/"modifier"/"piece", data: ..., instance: ...}
	
	for relic in _extra_inventory.relics:
		items.append({"type": "relic", "instance": relic, "data": relic.data})
	
	for modifier in _extra_inventory.modifiers:
		items.append({"type": "modifier", "instance": null, "data": modifier})
	
	for piece in _extra_inventory.slot_pieces:
		items.append({"type": "piece", "instance": piece, "data": piece.data})
	
	# Display items in slots using ItemUI
	for i in range(slots.size()):
		var slot_ui = slots[i] as SlotUI
		if not slot_ui:
			continue
		
		# Connect signal for relic drop from relic slot back to inventory (only once)
		if not slot_ui.extra_item_dropped.is_connected(_on_extra_item_returned):
			slot_ui.extra_item_dropped.connect(_on_extra_item_returned)
		
		if i < items.size():
			var item = items[i]
			slot_ui.set_extra_item(item.type, item.data, item.instance)
		else:
			slot_ui.clear_display()


## Handle item returned to other_inventory (e.g., relic dragged from relic slot)
func _on_extra_item_returned(item_type: String, item_data: Variant, item_instance: Variant, _target_slot_ui: SlotUI) -> void:
	if item_type == "relic" and item_instance is RelicInstance:
		var relic = item_instance as RelicInstance
		
		# Remove from the panel it was attached to
		if _panel_manager and relic.attached_panel_index >= 0:
			var panel = _panel_manager.get_panel(relic.attached_panel_index)
			if panel:
				panel.detach_relic(relic)
		
		# Clear its panel attachment
		relic.detach_from_panel()
		
		# Add back to extra inventory
		if _extra_inventory:
			_extra_inventory.add_relic(relic)
		
		# Update displays
		_update_other_inventory_display()
		_update_relic_slots_display()
