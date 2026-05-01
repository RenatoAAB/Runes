class_name MainController
extends Node

## The "Glue" script that connects Logic to UI.
## Attaches to the Root Node of the Main Scene.

## Emitted when all managers and UI are initialized and ready
signal initialization_complete

@export_group("Managers")
@export var game_manager: GameManager
@export var inventory_manager: InventoryManager

## GridManager and Reader are obtained from the active panel via PanelManager
## These are set by _bind_active_panel_nodes()
var grid_manager: GridManager = null
var reader: Reader = null

@export_group("UI Containers")
@export var grid_container: Control # GridContainer
@export var inventory_container: Control # Single container for runes + extra items
@export var relic_slots_container: Control # Container for 3 relic slots per panel
@export var score_label: Label
@export var level_label: Label
@export var target_value_label: Label
@export var money_label: Label
@export var panel_label: Label  # Shows current panel (e.g., "Panel 1/3")
@export var enter_shop_button: Button
@export var activator_node: Node2D
@export var previous_panel_button: Button
@export var next_panel_button: Button

# Shop references (now from scene)
@export_group("Shop")
@export var shop_ui: ShopUI
var _shop_manager: ShopManager = null

# Panel system
var _panel_manager: PanelManager = null
var _extra_inventory: ExtraInventoryManager = null
var _relic_slot_uis: Array[SlotUI] = []
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

## Tracks which grid coords are currently highlighted for piece drag preview
var _piece_preview_coords: Array[Vector2i] = []
## Tracks the last coord used for piece drag preview (to avoid redundant updates)
var _piece_preview_last_coord: Vector2i = Vector2i(-999, -999)

func _ready() -> void:
	print("[MainController] Initialization starting...")
	
	# Add to main_controller group
	add_to_group("main_controller")
	
	# Validate required exports
	assert(game_manager != null, "MainController: game_manager export is required")
	assert(inventory_manager != null, "MainController: inventory_manager export is required")
	
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
		if not reader.relic_step_started.is_connected(_on_relic_step_started):
			reader.relic_step_started.connect(_on_relic_step_started)
		if not reader.relic_step_completed.is_connected(_on_relic_step_completed):
			reader.relic_step_completed.connect(_on_relic_step_completed)
		if not reader.relic_processing_finished.is_connected(_on_relic_processing_finished):
			reader.relic_processing_finished.connect(_on_relic_processing_finished)
		
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
		grid_highlighter.request_value_source_highlight.connect(_on_request_value_source_highlight)
	
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
	
	# Pass PanelManager reference to GameManager for direct access
	if game_manager and _panel_manager:
		game_manager.set_panel_manager(_panel_manager)
		print("[MainController] PanelManager reference passed to GameManager")
	
	# Register UI references with JuiceManager
	_register_juice_manager()
	
	print("[MainController] Initialization complete!")
	# Signal that initialization is complete - GameManager waits for this
	initialization_complete.emit()


## Register UI node references with the JuiceManager autoload
func _register_juice_manager() -> void:
	var juice = get_node_or_null("/root/JuiceManager")
	if not juice:
		return
	juice.register_score_label(score_label)
	juice.register_level_labels(level_label, target_value_label)
	juice.register_grid_ui_slots(grid_ui_slots)


## Refresh shop inventory (called after victory or manual reroll)
func refresh_shop() -> void:
	if not _shop_manager:
		push_warning("MainController.refresh_shop() called but _shop_manager is null")
		return
	if not game_manager:
		push_warning("MainController.refresh_shop() called but game_manager is null")
		return
	_shop_manager.refresh_shop(game_manager.current_level)


## Initialize the panel management system
func _initialize_panel_system() -> void:
	print("[MainController] Initializing panel system...")
	
	# Create PanelManager
	_panel_manager = PanelManager.new()
	_panel_manager.name = "PanelManager"
	add_child(_panel_manager)
	_panel_manager.add_to_group("panel_manager")
	_panel_manager.initialize_default()
	print("[MainController] PanelManager created with %d panels" % _panel_manager.panels.size())
	
	# Instantiate grids/readers for unlocked panels at game start
	var initial_step_delay = reader.step_delay if reader else -1.0
	_panel_manager.setup_all_panels(self, initial_step_delay)
	_bind_active_panel_nodes()
	print("[MainController] Panel nodes bound (grid_manager=%s, reader=%s)" % [grid_manager != null, reader != null])
	
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
	
	# Create ShopManager early so it's available for refresh_shop calls
	_shop_manager = ShopManager.new()
	_shop_manager.name = "ShopManager"
	add_child(_shop_manager)


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
	if grid_highlighter and grid_highlighter.has_method("set_grid_manager"):
		grid_highlighter.set_grid_manager(grid_manager)
	
	if grid_manager and not grid_manager.slot_changed.is_connected(_on_grid_slot_changed):
		grid_manager.slot_changed.connect(_on_grid_slot_changed)
	if reader:
		if not reader.step_started.is_connected(_on_reader_step):
			reader.step_started.connect(_on_reader_step)
		if not reader.step_completed.is_connected(_on_reader_step_done):
			reader.step_completed.connect(_on_reader_step_done)
		if not reader.score_updated.is_connected(_on_score_updated):
			reader.score_updated.connect(_on_score_updated)
		if not reader.relic_step_started.is_connected(_on_relic_step_started):
			reader.relic_step_started.connect(_on_relic_step_started)
		if not reader.relic_step_completed.is_connected(_on_relic_step_completed):
			reader.relic_step_completed.connect(_on_relic_step_completed)
		if not reader.relic_processing_finished.is_connected(_on_relic_processing_finished):
			reader.relic_processing_finished.connect(_on_relic_processing_finished)
	
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
		if _bound_reader.relic_step_started.is_connected(_on_relic_step_started):
			_bound_reader.relic_step_started.disconnect(_on_relic_step_started)
		if _bound_reader.relic_step_completed.is_connected(_on_relic_step_completed):
			_bound_reader.relic_step_completed.disconnect(_on_relic_step_completed)
		if _bound_reader.relic_processing_finished.is_connected(_on_relic_processing_finished):
			_bound_reader.relic_processing_finished.disconnect(_on_relic_processing_finished)
	_bound_grid_manager = null
	_bound_reader = null


## Configure relic slots from scene children (SlotUI instances)
func _generate_relic_slots() -> void:
	if not relic_slots_container:
		return
	_relic_slot_uis.clear()
	
	var idx := 0
	for child in relic_slots_container.get_children():
		var slot_ui = child as SlotUI
		if not slot_ui:
			continue
		slot_ui.is_relic_slot = true
		slot_ui.set_slot_context(SlotUI.SlotContext.RELIC)
		slot_ui.relic_slot_index = idx
		slot_ui.relic_panel_index = _current_panel_index
		if not slot_ui.relic_slot_dropped.is_connected(_on_relic_dropped):
			slot_ui.relic_slot_dropped.connect(_on_relic_dropped)
		if not slot_ui.relic_slot_clicked.is_connected(_on_relic_clicked):
			slot_ui.relic_slot_clicked.connect(_on_relic_clicked)
		_relic_slot_uis.append(slot_ui)
		idx += 1
	
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
		slot_ui.relic_panel_index = _current_panel_index
		
		# Set relic if panel has one at this index
		if i < panel.attached_relics.size():
			var r = panel.attached_relics[i]
			slot_ui._relic_instance = r
			slot_ui.set_extra_item("relic", r.data, r)
		else:
			slot_ui._relic_instance = null
			slot_ui.clear_display()


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
func _on_relic_dropped(relic: RelicInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI) -> void:
	if not _panel_manager or not _extra_inventory:
		return
	
	var target_panel = _panel_manager.get_panel(target_slot_ui.relic_panel_index)
	if not target_panel:
		return
	
	# If relic comes from another relic slot, detach from that panel first
	if source_slot_ui and source_slot_ui.is_relic_slot:
		var source_panel = _panel_manager.get_panel(source_slot_ui.relic_panel_index)
		if source_panel:
			source_panel.detach_relic(relic)
		relic.detach_from_panel()
		source_slot_ui._relic_instance = null
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
		relic.attach_to_panel(target_slot_ui.relic_panel_index)
		target_slot_ui._relic_instance = relic
	
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

## Handles value source highlight requests from GridHighlighter.
func _on_request_value_source_highlight(coord: Vector2i, effect_indices: Array) -> void:
	if grid_ui_slots.has(coord):
		grid_ui_slots[coord].set_value_source_highlight(effect_indices)

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
			
			slot_ui.set_slot_context(SlotUI.SlotContext.PANEL)
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

	# Update JuiceManager with new grid references
	var juice = get_node_or_null("/root/JuiceManager")
	if juice:
		juice.register_grid_ui_slots(grid_ui_slots)


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
	inventory_ui_slots.clear()
	
	# Use the existing slots from the scene
	for slot_node in inventory_container.get_children():
		var slot_ui = slot_node as SlotUI
		if not slot_ui:
			continue
		
		if default_tooltip_label_settings:
			slot_ui.tooltip_label_settings = default_tooltip_label_settings
		
		slot_ui.set_slot_context(SlotUI.SlotContext.INVENTORY)
		# Connect signals
		if not slot_ui.rune_dropped.is_connected(_on_rune_dropped):
			slot_ui.rune_dropped.connect(_on_rune_dropped)
		if not slot_ui.extra_item_dropped.is_connected(_on_extra_item_returned):
			slot_ui.extra_item_dropped.connect(_on_extra_item_returned)
		
		inventory_ui_slots.append(slot_ui)

func _create_slot_ui() -> SlotUI:
	if slot_scene:
		return slot_scene.instantiate() as SlotUI
	else:
		# Fallback if no scene assigned: Create programmatically
		var slot = SlotUI.new()
		slot.custom_minimum_size = Vector2(40, 40)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.position = Vector2(20, 20)
		sprite.texture = load("res://sprites/slots/base_slot-export.png") as Texture2D
		slot.add_child(sprite)
		return slot

# --- Signal Handlers ---

func _on_inventory_updated() -> void:
	_update_other_inventory_display()

func _on_grid_slot_changed(coord: Vector2i) -> void:
	if grid_ui_slots.has(coord):
		var slot_ui = grid_ui_slots[coord]
		var logic_slot = grid_manager.get_slot(coord)
		slot_ui.set_rune(logic_slot.rune)
		slot_ui.update_slot_info(logic_slot)


func _on_rune_dropped(rune: RuneInstance, target_slot_ui: SlotUI, source_slot_ui: SlotUI) -> void:
	# Determine source and destination
	print("Rune Dropped. Source: %s, Target: %s" % [source_slot_ui, target_slot_ui])

	var success := false

	# Case 1: Drop on Grid
	if target_slot_ui.grid_coord != Vector2i(-1, -1):
		if inventory_manager.has_rune(rune):
			# Move from Inventory -> Grid (keep RuneInstance to preserve permanent buffs)
			if grid_manager.place_rune_instance(rune, target_slot_ui.grid_coord):
				inventory_manager.remove_rune(rune)
				success = true
		else:
			# Move from Grid -> Grid (Swap/Move)
			var source_coord = _find_rune_coord(rune)
			if source_coord != Vector2i(-1, -1):
				grid_manager.move_rune(source_coord, target_slot_ui.grid_coord)
				success = true

	# Case 2: Drop on Inventory (Unequip)
	elif target_slot_ui.grid_coord == Vector2i(-1, -1):
		# Move Grid -> Inventory
		var source_coord = _find_rune_coord(rune)
		if source_coord != Vector2i(-1, -1):
			# Remove from grid
			var slot = grid_manager.get_slot(source_coord)
			slot.remove_rune()
			grid_manager.slot_changed.emit(source_coord)
			inventory_manager.add_rune(rune)
			success = true

	# Notify EventBus for SFX
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.drag_ended.emit(success)

	# Juice: drop impact or return settle
	var juice = get_node_or_null("/root/JuiceManager")
	if juice:
		if success and target_slot_ui.grid_coord != Vector2i(-1, -1):
			juice.notify_rune_dropped_on_slot(target_slot_ui)
		elif not success or target_slot_ui.grid_coord == Vector2i(-1, -1):
			juice.notify_rune_returned_to_inventory(target_slot_ui)


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
	
	# Clear the drag preview before modifying the grid
	clear_piece_drag_preview()
	
	# Unlock slots from the piece
	var unlocked_count = panel.unlock_slots_from_piece(piece, coord)
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


## Show drag preview highlighting the grid slots a piece would cover.
## Called from SlotUI._can_drop_data during piece drag.
func show_piece_drag_preview(piece_data: SlotPieceData, base_coord: Vector2i) -> void:
	# Skip redundant updates for the same coord
	if base_coord == _piece_preview_last_coord:
		return
	
	clear_piece_drag_preview()
	_piece_preview_last_coord = base_coord
	
	if not _panel_manager:
		return
	var panel := _panel_manager.get_panel(_current_panel_index)
	if not panel:
		return
	
	var is_valid := panel.can_place_piece(piece_data.shape, base_coord)
	var color := Color(0.2, 0.8, 0.2, 0.4) if is_valid else Color(0.8, 0.2, 0.2, 0.4)
	
	for offset in piece_data.shape:
		var coord := base_coord + offset
		_piece_preview_coords.append(coord)
		var slot_ui: SlotUI = grid_ui_slots.get(coord) as SlotUI
		if slot_ui:
			slot_ui.set_buff_highlight(color)


## Clear all piece drag preview highlights from the grid.
func clear_piece_drag_preview() -> void:
	for coord in _piece_preview_coords:
		var slot_ui: SlotUI = grid_ui_slots.get(coord) as SlotUI
		if slot_ui:
			slot_ui.set_buff_highlight(Color(0, 0, 0, 0))
	_piece_preview_coords.clear()
	_piece_preview_last_coord = Vector2i(-999, -999)


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
		# Let JuiceManager handle the text update via counting animation
		var juice = get_node_or_null("/root/JuiceManager")
		if juice:
			juice.notify_score_updated(new_total)
		else:
			score_label.text = "Score: %d" % new_total


## --- Relic visual highlight callbacks ---

func _on_relic_step_started(relic_index: int, _relic: RelicInstance) -> void:
	if relic_index >= 0 and relic_index < _relic_slot_uis.size():
		var slot_ui = _relic_slot_uis[relic_index]
		slot_ui.set_buff_highlight(Color(1.0, 0.85, 0.0, 0.55))  # Gold highlight

func _on_relic_step_completed(relic_index: int, _relic: RelicInstance, multiplier: float) -> void:
	if relic_index >= 0 and relic_index < _relic_slot_uis.size():
		var slot_ui = _relic_slot_uis[relic_index]
		# Brief green/red flash based on multiplier, then clear
		var flash_color = Color(0.3, 1.0, 0.3, 0.5) if multiplier > 1.0 else Color(0.5, 0.5, 0.5, 0.2)
		slot_ui.set_buff_highlight(flash_color)
		var tween = slot_ui.create_tween()
		tween.tween_property(slot_ui.buff_rect, "color", Color.TRANSPARENT, 0.3)

func _on_relic_processing_finished(_combined_multiplier: float) -> void:
	# Ensure all highlights are cleared
	for slot_ui in _relic_slot_uis:
		slot_ui.set_buff_highlight(Color.TRANSPARENT)


func _on_economy_changed(_event) -> void:
	_update_money_display()


func _update_money_display() -> void:
	if money_label:
		var stats = get_node_or_null("/root/Stats")
		var money = stats.get_money() if stats else 0
		money_label.text = "%d Mana" % money
		money_label.mouse_filter = Control.MOUSE_FILTER_STOP
		# Connect hover signals once for tooltip
		if not money_label.mouse_entered.is_connected(_on_money_hover):
			money_label.mouse_entered.connect(_on_money_hover)
			money_label.mouse_exited.connect(_on_money_hover_end)


func _on_money_hover() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if not tooltip_manager:
		return
	var stats = get_node_or_null("/root/Stats")
	var money = stats.get_money() if stats else 0
	var interest = mini(money / 5, ShopConfig.MAX_INTEREST)
	var text = "[color=yellow]+ %d[/color] de geração espontânea" % interest
	tooltip_manager.show_tooltip(text)


func _on_money_hover_end() -> void:
	var tooltip_manager = get_tree().get_first_node_in_group("tooltip_manager")
	if tooltip_manager:
		tooltip_manager.hide_tooltip()


func _on_level_started(level: int, target: int) -> void:
	if level_label:
		level_label.text = "Level %d" % level
	if target_value_label:
		target_value_label.text = "%d" % target


func _on_phase_changed(new_phase: GameEnums.GamePhase) -> void:
	match new_phase:
		GameEnums.GamePhase.BATTLE:
			# Hide shop during battle
			_hide_shop()
			# Hide enter shop button during battle
			if enter_shop_button:
				enter_shop_button.visible = false
		GameEnums.GamePhase.RESOLUTION:
			pass  # BattleResultScreen handles end-of-round display
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
	if activator_node:
		activator_node.visible = false
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
	
	# Keep inventory container visible
	if inventory_container:
		inventory_container.visible = true
	
	# Keep money label visible
	if money_label:
		money_label.visible = true
	
	# ShopManager is now created in _initialize_panel_system()
	if not _shop_manager:
		push_error("MainController._show_shop() called but _shop_manager was not initialized!")
		return
	
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
		
		# Initialize with shop manager (but don't refresh shop items yet)
		var level = game_manager.current_level if game_manager else 1
		shop_ui.initialize(_shop_manager, level, false)
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
	if activator_node:
		activator_node.visible = true
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
	
	# Keep inventory container visible (always visible)
	if inventory_container:
		inventory_container.visible = true
	
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


## Check if the shared inventory is full (runes + extra items >= available UI slots)
func is_inventory_full() -> bool:
	var total_items: int = inventory_manager.get_rune_count()
	if _extra_inventory:
		total_items += _extra_inventory.relics.size()
		total_items += _extra_inventory.modifiers.size()
		total_items += _extra_inventory.slot_pieces.size()
	return total_items >= inventory_ui_slots.size()


# --- Extra Inventory (Pieces, Modifiers, Relics) Display ---

func _on_extra_inventory_updated() -> void:
	_update_other_inventory_display()


## Update InventoryContainer to show runes and extra items from both inventories
func _update_other_inventory_display() -> void:
	if inventory_ui_slots.is_empty():
		return
	
	# Collect rune items from InventoryManager
	var all_items: Array = []  # {type: "rune"/"relic"/"modifier"/"piece", ...}
	
	for i in range(inventory_manager.max_slots):
		var rune = inventory_manager.get_rune_at(i)
		if rune:
			all_items.append({"type": "rune", "instance": rune, "inventory_index": i})
	
	# Collect extra items from ExtraInventory
	if _extra_inventory:
		for relic in _extra_inventory.relics:
			all_items.append({"type": "relic", "instance": relic, "data": relic.data})
		
		for modifier in _extra_inventory.modifiers:
			all_items.append({"type": "modifier", "instance": null, "data": modifier})
		
		for piece in _extra_inventory.slot_pieces:
			all_items.append({"type": "piece", "instance": piece, "data": piece.data})
	
	# Display items in inventory slots
	for i in range(inventory_ui_slots.size()):
		var slot_ui = inventory_ui_slots[i]
		
		if i < all_items.size():
			var item = all_items[i]
			if item.type == "rune":
				slot_ui.inventory_index = item.inventory_index
				slot_ui.set_rune(item.instance)
			else:
				slot_ui.inventory_index = -1
				slot_ui.set_extra_item(item.type, item.data, item.instance)
		else:
			slot_ui.inventory_index = -1
			slot_ui.set_rune(null)
			slot_ui.clear_display()


## Add initial extra inventory items (called by GameManager)
func add_initial_extra_items(relics: Array[RelicData], modifiers: Array[SlotModifierData], pieces: Array[SlotPieceData]) -> void:
	if not _extra_inventory:
		push_warning("MainController.add_initial_extra_items: _extra_inventory is null")
		return
	
	for relic_data in relics:
		var instance = RelicInstance.new(relic_data)
		_extra_inventory.add_relic(instance)
	
	for modifier in modifiers:
		_extra_inventory.add_modifier(modifier)
	
	for piece_data in pieces:
		var instance = SlotPieceInstance.new(piece_data)
		_extra_inventory.add_slot_piece(instance)

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
