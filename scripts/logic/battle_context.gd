class_name BattleContext
extends RefCounted

## A context object passed through the effect chain during execution.
## Acts as the API for effects to interact with the game state (Grid, Score, etc.)
## without coupling directly to Nodes like Reader or Main.

signal score_event(amount: int, source: RuneInstance)
signal reader_jump_request(index: int)
signal rune_activation_queued(slot: GridSlot)

var grid: GridManager
var current_score: int = 0
var current_step_index: int = 0
var queued_activations: Array[GridSlot] = []

func _init(p_grid: GridManager):
	grid = p_grid

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
