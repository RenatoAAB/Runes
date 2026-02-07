class_name GameManager
extends Node

signal level_started(level: int, target_score: int)
signal game_won
signal game_lost(final_level: int)
signal phase_changed(new_phase: GameEnums.GamePhase)
signal rune_selection_requested(options: Array[RuneData])
signal upgrade_requested(runes: Array[RuneInstance])
signal free_pick_granted(count: int)  # Signals free rune picks available

## Alias for backwards compatibility - use GameEnums.GamePhase directly
const GamePhase = GameEnums.GamePhase

## Reader is now obtained from the active panel via PanelManager
var reader: Reader:
	get:
		if _panel_manager:
			var panel = _panel_manager.get_active_panel()
			if panel:
				return panel.reader
		return null

## GridManager is now obtained from the active panel via PanelManager
var grid_manager: GridManager:
	get:
		if _panel_manager:
			var panel = _panel_manager.get_active_panel()
			if panel:
				return panel.grid_manager
		return null

@export var inventory_manager: InventoryManager

# Curve settings
@export var base_target_score: int = 50
@export var score_growth_per_level: float = 1.5

var current_level: int = 1
var current_target_score: int = 0
var current_phase: GamePhase = GamePhase.SETUP
var is_initial_setup: bool = true

# Runes that start in the player's inventory
@export var initial_runes: Array[RuneData]
# Items that start in the player's extra inventory
@export var initial_relics: Array[RelicData]
@export var initial_modifiers: Array[SlotModifierData]
@export var initial_slot_pieces: Array[SlotPieceData]
# Runes available for rewards/shop (loaded dynamically)
var available_runes: Array[RuneData]
@export var rune_drop_rates: RuneDropRates
var _panel_manager: PanelManager = null
var _main_controller: Node = null  # Reference set during initialization


## Set the PanelManager reference directly (called by MainController)
func set_panel_manager(pm: PanelManager) -> void:
	if _panel_manager == pm:
		return
	_panel_manager = pm
	print("[GameManager] PanelManager reference set (panels=%d)" % pm.panels.size())
	if _panel_manager and not _panel_manager.all_panels_completed.is_connected(_on_battle_finished):
		_panel_manager.all_panels_completed.connect(_on_battle_finished)


func _ready() -> void:
	print("[GameManager] Initialization starting...")
	add_to_group("game_manager")
	
	# Validate required exports
	assert(inventory_manager != null, "GameManager: inventory_manager export is required")
	
	# Reader signal connection is now handled by PanelManager
	
	# Load all runes dynamically if not set in inspector
	if available_runes.is_empty():
		_load_all_runes()
	
	print("[GameManager] Waiting for MainController initialization...")
	# Wait for MainController to complete initialization before starting game
	# This ensures PanelManager and other dependencies are ready
	_wait_for_initialization()


## Wait for MainController initialization before starting game
func _wait_for_initialization() -> void:
	# Try to find MainController
	var main_controller = get_tree().get_first_node_in_group("main_controller")
	
	if main_controller:
		_main_controller = main_controller
		# Check if it has initialization_complete signal
		if main_controller.has_signal("initialization_complete"):
			# Connect and wait
			if not main_controller.initialization_complete.is_connected(_on_main_controller_ready):
				main_controller.initialization_complete.connect(_on_main_controller_ready, CONNECT_ONE_SHOT)
			return
	
	# Fallback: if MainController not found or no signal, use deferred call
	push_warning("GameManager: MainController not found, using deferred start_game")
	call_deferred("start_game")


func _on_main_controller_ready() -> void:
	print("[GameManager] MainController ready signal received")
	# Validate that PanelManager was set
	if not _panel_manager:
		push_error("GameManager: PanelManager was not set by MainController!")
	# MainController is fully initialized, safe to start game
	start_game()


func _bind_panel_manager() -> void:
	if _panel_manager:
		return
	# Fallback: try to find via group if not set directly
	var node = get_tree().get_first_node_in_group("panel_manager")
	if node and node is PanelManager:
		_panel_manager = node
		if not _panel_manager.all_panels_completed.is_connected(_on_battle_finished):
			_panel_manager.all_panels_completed.connect(_on_battle_finished)

func _load_all_runes() -> void:
	var rune_folders = [
		"res://resources/runes/common/",
		"res://resources/runes/uncommon/",
		"res://resources/runes/rare/",
		"res://resources/runes/epic/",
		"res://resources/runes/legendary/"
	]
	
	for folder_path in rune_folders:
		var dir = DirAccess.open(folder_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var rune_path = folder_path + file_name
					var rune_data = load(rune_path) as RuneData
					if rune_data:
						available_runes.append(rune_data)
						print("Loaded rune: %s" % rune_data.rune_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	
	print("Total runes loaded: %d" % available_runes.size())

func start_game() -> void:
	current_level = 1
	is_initial_setup = true
	_bind_panel_manager()

	if _panel_manager:
		_panel_manager.full_reset_all_panels()
	
	# Clear all grids via panel manager (grid_manager getter may return null before panels are ready)
	if grid_manager:
		grid_manager.clear_grid()
	
	# Reset run statistics (including money) when starting a new game
	var stats = get_node_or_null("/root/Stats")
	if stats and stats.has_method("start_new_run"):
		stats.start_new_run()
	
	# Refresh shop inventory at game start
	_refresh_shop_after_victory()
	
	_setup_initial_inventory()
	# start_level() is now called by select_rune_reward after the player makes their choice.

func start_level() -> void:
	is_initial_setup = false
	current_target_score = _calculate_target_score(current_level)
	
	# Refresh shop inventory at the start of each level
	_refresh_shop_after_victory()
	
	current_phase = GamePhase.PLANNING
	phase_changed.emit(current_phase)
	level_started.emit(current_level, current_target_score)
	print("Level %d Started. Target: %d" % [current_level, current_target_score])

func start_battle() -> void:
	if current_phase != GamePhase.PLANNING:
		print("Cannot start battle. Current phase: %s" % GamePhase.keys()[current_phase])
		return

	current_phase = GamePhase.BATTLE
	phase_changed.emit(current_phase)

	# Delegate battle flow to PanelManager (supports multi-panel even with one panel)
	if _panel_manager and _panel_manager.has_method("start_multi_panel_battle"):
		_panel_manager.start_multi_panel_battle()
	else:
		# Fallback: start reader directly if no panel manager is present
		if reader:
			reader.start_sequence()
		else:
			push_error("No reader or panel manager available to start battle")

## Reference to current result screen (if any)
var _result_screen: BattleResultScreen = null
var _last_battle_score: int = 0

func _on_battle_finished(total_score: int) -> void:
	current_phase = GamePhase.RESOLUTION
	phase_changed.emit(current_phase)
	_last_battle_score = total_score
	
	print("Battle Finished. Score: %d / %d" % [total_score, current_target_score])
	
	var is_victory = total_score >= current_target_score
	
	# Show result screen with statistics
	_show_result_screen(is_victory, total_score)


func _show_result_screen(is_victory: bool, total_score: int) -> void:
	# Find a parent node for the result screen (preferably the UI layer)
	var ui_parent = get_tree().get_first_node_in_group("ui_layer")
	if not ui_parent:
		ui_parent = get_tree().root
	
	_result_screen = BattleResultScreen.create_popup(
		ui_parent,
		is_victory,
		total_score,
		current_target_score
	)
	
	_result_screen.continue_pressed.connect(_on_result_continue.bind(is_victory))


func _on_result_continue(was_victory: bool) -> void:
	if _result_screen:
		_result_screen.queue_free()
		_result_screen = null
	
	if was_victory:
		_handle_win()
	else:
		_handle_loss()


func _handle_win() -> void:
	print("Victory!")
	
	# Grant money reward for winning
	_grant_victory_money()
	
	# Refresh shop after victory
	_refresh_shop_after_victory()
	
	# Go to planning phase (shop is available during planning)
	_finish_level_transition()


func _grant_victory_money() -> void:
	# Base reward + bonus per level (level 1 gives 5, level 2 gives 6, etc.)
	var base_reward = 4
	var level_bonus = current_level
	var total_reward = base_reward + level_bonus
	
	# Emit economy event
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var stats = get_node_or_null("/root/Stats")
		var balance = stats.get_money() if stats else 0
		var event = EconomyEvent.create_round_bonus(current_level, total_reward, balance)
		event_bus.emit(event)
	
	print("Granted $%d for winning level %d" % [total_reward, current_level])


func _refresh_shop_after_victory() -> void:
	# Use direct reference to MainController if available
	if _main_controller and _main_controller.has_method("refresh_shop"):
		_main_controller.refresh_shop()
	else:
		# Fallback: find via group
		var main_controller = get_tree().get_first_node_in_group("main_controller")
		if main_controller and main_controller.has_method("refresh_shop"):
			main_controller.refresh_shop()


func _handle_loss() -> void:
	print("Defeat!")
	game_lost.emit(current_level)
	# Restart or Game Over logic
	# For now, just restart
	start_game()

func _calculate_target_score(level: int) -> int:
	# Simple exponential curve
	return int(base_target_score * pow(score_growth_per_level, level - 1))

func _setup_initial_inventory() -> void:
	# Clear inventory
	inventory_manager.clear_all()
	_main_controller = get_tree().get_first_node_in_group("main_controller")
	if _main_controller and _main_controller.has_method("add_initial_extra_items"):
		_main_controller.add_initial_extra_items(initial_relics, initial_modifiers, initial_slot_pieces)
	
	# Add initial runes to inventory
	for rune_data in initial_runes:
		var instance = RuneInstance.new(rune_data)
		inventory_manager.add_rune(instance)

	# Give starting money
	_grant_starting_money()
	
	# Grant first free rune pick
	free_pick_granted.emit(1)
	
	# Start the first level (shop is available during planning)
	start_level()


func _grant_starting_money() -> void:
	var starting_money = 10
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		var event = EconomyEvent.new()
		event.transaction_type = EconomyEvent.TransactionType.ROUND_BONUS
		event.source = &"starting_bonus"
		event.amount = starting_money
		event.balance_before = 0
		event.balance_after = starting_money
		event.description = "Starting bonus"
		event_bus.emit(event)
	print("Granted $%d starting money" % starting_money)


func _trigger_rune_selection() -> void:
	var options = _generate_rune_options(3)
	current_phase = GamePhase.REWARD
	phase_changed.emit(current_phase)
	rune_selection_requested.emit(options)
	print("Rune Selection Requested")

func select_rune_reward(rune_data: RuneData) -> void:
	if current_phase != GamePhase.REWARD:
		print("Error: select_rune_reward called but phase is %s" % GamePhase.keys()[current_phase])
		return
		
	var instance = RuneInstance.new(rune_data)
	if inventory_manager.add_rune(instance):
		print("Selected Reward: %s" % rune_data.rune_name)
	else:
		print("Error: Failed to add reward to inventory (Full?)")
	
	# If we are in setup (level 1), start the level
	if is_initial_setup:
		start_level()
	else:
		# If this was a mid-game reward, proceed to upgrade phase
		_trigger_upgrade_phase()

func _trigger_upgrade_phase() -> void:
	current_phase = GamePhase.UPGRADE
	phase_changed.emit(current_phase)
	
	# Filter upgradeable runes (those that have an upgrade)
	var upgradeable_runes: Array[RuneInstance] = []
	
	# Check Inventory
	for rune in inventory_manager.runes:
		if rune.data.upgrades_to != null:
			upgradeable_runes.append(rune)
	
	# Check Grid
	for slot in grid_manager.grid:
		if slot.rune and slot.rune.data.upgrades_to != null:
			upgradeable_runes.append(slot.rune)
			
	upgrade_requested.emit(upgradeable_runes)
	print("Upgrade Requested")
	
	# If no runes can be upgraded, skip to next level
	if upgradeable_runes.is_empty():
		print("No upgradeable runes, skipping upgrade.")
		_finish_level_transition()

func confirm_upgrade(rune_instance: RuneInstance) -> void:
	if current_phase != GamePhase.UPGRADE:
		return
		
	if rune_instance.data.upgrades_to:
		print("Upgrading %s to %s" % [rune_instance.data.rune_name, rune_instance.data.upgrades_to.rune_name])
		rune_instance.data = rune_instance.data.upgrades_to
		# Notify inventory update if needed, though modifying the instance might be enough if signals are set up right.
		# InventoryManager emits 'inventory_updated' on add/remove, but maybe not on internal change.
		# We might want to force an update signal.
		inventory_manager.inventory_updated.emit()
	
	_finish_level_transition()

func _finish_level_transition() -> void:
	current_level += 1
	start_level()





func _generate_rune_options(count: int = 3) -> Array[RuneData]:
	var options: Array[RuneData] = []
	# Filter for Tier 1 runes only
	var tier1_runes = available_runes.filter(func(r): return r.tier == GameEnums.Tier.TIER_1)
	
	if tier1_runes.is_empty():
		return []
		
	# Create a copy to avoid picking the same one multiple times if desired, 
	# but usually duplicates are allowed or we remove them. 
	# Let's allow duplicates for now or try to pick distinct ones if possible.
	var pool = tier1_runes.duplicate()
	
	for i in range(count):
		if pool.is_empty():
			break
		var picked = _pick_weighted_rune(pool)
		if picked:
			options.append(picked)
			# Optional: Remove picked to ensure distinct options
			pool.erase(picked)
			
	return options

func _pick_weighted_rune(pool: Array[RuneData]) -> RuneData:
	if pool.is_empty():
		return null
		
	if not rune_drop_rates:
		return pool.pick_random()
		
	var total_weight = 0
	for rune in pool:
		total_weight += rune_drop_rates.get_weight(rune.rarity)
		
	var roll = randi() % total_weight
	var current_weight = 0
	for rune in pool:
		current_weight += rune_drop_rates.get_weight(rune.rarity)
		if roll < current_weight:
			return rune
			
	return pool[0]

func _grant_reward() -> void:
	# Deprecated or used for debug
	pass

func _on_battle_button_pressed() -> void:
	start_battle()

