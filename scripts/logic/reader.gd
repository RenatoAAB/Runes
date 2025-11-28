class_name Reader
extends Node

## The core game loop executor.
## Iterates through the grid sequentially and triggers runes.

signal step_started(coord: Vector2i)
signal step_completed(coord: Vector2i)
signal sequence_finished(total_score: int)
signal score_updated(new_total: int)

@export var grid_manager: GridManager
@export var step_delay: float = 0.5

var is_running: bool = false
var current_index: int = 0
var total_score: int = 0
var battle_context: BattleContext

func start_sequence() -> void:
	if is_running:
		return
	
	is_running = true
	current_index = 0
	total_score = 0
	
	# Initialize BattleContext
	battle_context = BattleContext.new(grid_manager)
	battle_context.score_event.connect(_on_score_event)
	
	# Reset grid state before starting
	grid_manager.process_round_end()
	
	_process_next_step()

func _process_next_step() -> void:
	if current_index >= GridManager.GRID_SIZE * GridManager.GRID_SIZE:
		_finish_sequence()
		return
	
	var y = current_index / GridManager.GRID_SIZE
	var x = current_index % GridManager.GRID_SIZE
	var coord = Vector2i(x, y)
	
	step_started.emit(coord)
	
	var slot = grid_manager.get_slot(coord)
	if slot and not slot.is_empty():
		_activate_rune(slot)
	
	# Wait for visual feedback
	await get_tree().create_timer(step_delay).timeout
	
	step_completed.emit(coord)
	current_index += 1
	
	if is_running: # Check in case stopped mid-sequence
		_process_next_step()

func _activate_rune(slot: GridSlot) -> void:
	var rune = slot.rune
	if rune.can_activate():
		rune.on_activate(battle_context, slot)

func _on_score_event(amount: int, source: RuneInstance) -> void:
	total_score += amount
	score_updated.emit(total_score)

func _finish_sequence() -> void:
	is_running = false
	sequence_finished.emit(total_score)
	# Clean up context signals if needed, though RefCounted handles memory
	if battle_context:
		battle_context.score_event.disconnect(_on_score_event)
		battle_context = null

func stop_sequence() -> void:
	is_running = false
