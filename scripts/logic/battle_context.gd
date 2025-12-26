class_name BattleContext
extends RefCounted

## A context object passed through the effect chain during execution.
## Acts as the API for effects to interact with the game state (Grid, Score, etc.)
## without coupling directly to Nodes like Reader or Main.
## 
## In the new event-driven architecture, BattleContext still provides the API
## but also tracks metadata for event generation.

signal score_event(amount: int, source: RuneInstance)
signal reader_jump_request(index: int)
signal rune_activation_queued(slot: GridSlot)

var grid: GridManager
var current_score: int = 0
var current_step_index: int = 0
var queued_activations: Array[GridSlot] = []

## Tracking for event generation
var current_slot: GridSlot = null
var current_rune: RuneInstance = null
var effects_this_activation: Array[Dictionary] = []  # Track effect results

## Reference to EventBus (optional, for direct event emission)
var event_bus: Node = null


func _init(p_grid: GridManager):
	grid = p_grid
	# Try to get EventBus
	if Engine.has_singleton("EventBus"):
		event_bus = Engine.get_singleton("EventBus")


## Set the current slot/rune being processed (called by Reader before activation)
func set_current_context(slot: GridSlot, rune: RuneInstance) -> void:
	current_slot = slot
	current_rune = rune
	effects_this_activation.clear()


## Record an effect execution result (called after each effect)
func record_effect_result(effect: RuneEffect, success: bool, score_delta: int, targets: Array[GridSlot]) -> void:
	effects_this_activation.append({
		"effect": effect,
		"success": success,
		"score_delta": score_delta,
		"targets": targets.map(func(s): return s.grid_position),
		"keywords": effect.get_keywords() if effect.has_method("get_keywords") else []
	})


func add_score(amount: int, source: RuneInstance) -> void:
	score_event.emit(amount, source)


func multiply_global_score(factor: float) -> void:
	# This is a special event, we might handle it by adding the difference
	var added = int(current_score * (factor - 1.0))
	if added != 0:
		score_event.emit(added, null) # Source null or a special "Global" source


func request_reader_jump(target_index: int) -> void:
	reader_jump_request.emit(target_index)


func queue_rune_activation(slot: GridSlot) -> void:
	if slot not in queued_activations:
		queued_activations.append(slot)
		rune_activation_queued.emit(slot)


func get_and_clear_queued_activations() -> Array[GridSlot]:
	var result = queued_activations.duplicate()
	queued_activations.clear()
	return result


## Get accumulated effect results for event generation
func get_effects_results() -> Array[Dictionary]:
	return effects_this_activation.duplicate()


## Clear effect tracking for next activation
func clear_effects_tracking() -> void:
	effects_this_activation.clear()
	current_slot = null
	current_rune = null
