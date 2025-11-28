class_name GameManager
extends Node

signal level_started(level: int, target_score: int)
signal game_won
signal game_lost(final_level: int)
signal phase_changed(new_phase: GamePhase)

enum GamePhase {
	SETUP,
	PLANNING,
	BATTLE,
	RESOLUTION
}

@export var reader: Reader
@export var inventory_manager: InventoryManager
@export var grid_manager: GridManager

# Curve settings
@export var base_target_score: int = 50
@export var score_growth_per_level: float = 1.5

var current_level: int = 1
var current_target_score: int = 0
var current_phase: GamePhase = GamePhase.SETUP

# Temporary database of runes to pick rewards from
@export var available_runes: Array[RuneData]

func _ready() -> void:
	if reader:
		reader.sequence_finished.connect(_on_battle_finished)
	
	# Start the game loop
	# In a real scene, we might wait for a "Start" button or main menu.
	# For this task, we auto-start.
	call_deferred("start_game")

func start_game() -> void:
	current_level = 1
	_setup_initial_inventory()
	start_level()

func start_level() -> void:
	current_target_score = _calculate_target_score(current_level)
	current_phase = GamePhase.PLANNING
	phase_changed.emit(current_phase)
	level_started.emit(current_level, current_target_score)
	print("Level %d Started. Target: %d" % [current_level, current_target_score])

func start_battle() -> void:
	if current_phase != GamePhase.PLANNING:
		return
	
	current_phase = GamePhase.BATTLE
	phase_changed.emit(current_phase)
	reader.start_sequence()

func _on_battle_finished(total_score: int) -> void:
	current_phase = GamePhase.RESOLUTION
	phase_changed.emit(current_phase)
	
	print("Battle Finished. Score: %d / %d" % [total_score, current_target_score])
	
	if total_score >= current_target_score:
		_handle_win()
	else:
		_handle_loss()

func _handle_win() -> void:
	print("Victory!")
	_grant_reward()
	current_level += 1
	# Loop back to planning for next level
	start_level()

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
	inventory_manager.runes.clear()
	
	# Add 4 random Tier 1 runes
	for i in range(4):
		_grant_reward()

func _grant_reward() -> void:
	var data: RuneData
	
	if available_runes.is_empty():
		# Create a dummy rune for testing if no data is assigned
		data = RuneData.new()
		data.rune_name = "Test Rune"
		data.element = GameEnums.Element.FIRE
		
		# Create a basic effect for the test rune
		var effect = RuneEffect.new()
		effect.condition = ConditionAlways.new()
		effect.target = TargetSelf.new()
		effect.payload = PayloadAddScore.new()
		data.effects = [effect]
	else:
		data = available_runes.pick_random()
	
	var instance = RuneInstance.new(data)
	inventory_manager.add_rune(instance)
	print("Reward Granted: %s" % data.rune_name)
