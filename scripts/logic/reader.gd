class_name Reader
extends Node

## The core game loop executor.
## Iterates through the grid sequentially and triggers runes.
## Emits events through EventBus for unified processing and recording.

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
var traversal_order: Array[Vector2i] = []

## Reference to EventBus autoload (set in _ready or via export)
var event_bus: Node = null

func _ready() -> void:
	# Try to get EventBus autoload
	if has_node("/root/EventBus"):
		event_bus = get_node("/root/EventBus")


func start_sequence() -> void:
	if is_running:
		return
	
	is_running = true
	current_index = 0
	total_score = 0
	
	# Initialize BattleContext
	battle_context = BattleContext.new(grid_manager)
	battle_context.score_event.connect(_on_score_event)
	battle_context.reader_jump_request.connect(_on_reader_jump_request)

	# Share references with EventBus so non-ON_READ triggers work
	if event_bus and event_bus.has_method("set_battle_references"):
		event_bus.set_battle_references(battle_context, grid_manager)

	# Build traversal order based on valid slots and share with context
	traversal_order = _build_traversal_order()
	battle_context.set_reader_path(traversal_order)
	
	# Reset grid state before starting
	grid_manager.process_round_end()
	
	if traversal_order.is_empty():
		_finish_sequence()
		return

	# Notify EventBus that battle is starting
	if event_bus and event_bus.has_method("begin_battle"):
		event_bus.begin_battle(1)  # 1 panel for now
		event_bus.begin_panel(0)
	
	_process_next_step()


func _build_traversal_order() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if not grid_manager:
		return coords
	
	# Traverse row-major order but include only non-void slots
	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var coord = Vector2i(x, y)
			var slot = grid_manager.get_slot(coord)
			if slot and not slot.is_void():
				coords.append(coord)
	return coords


func _process_next_step() -> void:
	if current_index >= traversal_order.size():
		_finish_sequence()
		return
	
	# Safety check for infinite loops or out of bounds
	if current_index < 0:
		current_index = 0
	
	var coord = traversal_order[current_index]
	var slot = grid_manager.get_slot(coord)
	
	# Skip any invalid/void slot defensively
	if not slot or slot.is_void():
		current_index += 1
		if is_running:
			_process_next_step()
		return
	
	# Update context with traversal index
	if battle_context:
		battle_context.current_step_index = current_index
	
	step_started.emit(coord)
	
	var score_before = total_score
	
	if slot and not slot.is_empty():
		_activate_rune(slot, coord, score_before)
	else:
		# Emit event for empty slot
		_emit_empty_slot_event(coord, score_before)
	
	# Wait for visual feedback
	await get_tree().create_timer(step_delay).timeout
	
	step_completed.emit(coord)
	current_index += 1
	
	if is_running: # Check in case stopped mid-sequence
		_process_next_step()


func _activate_rune(slot: GridSlot, coord: Vector2i, score_before: int) -> void:
	var rune = slot.rune
	
	if rune.is_disabled:
		_emit_disabled_slot_event(coord, rune, score_before)
		return
	
	if rune.can_activate():
		# Set context before activation so slot multiplier can be applied
		battle_context.set_current_context(slot, rune)
		
		# Capture state before activation
		var activations_before = rune.current_activations
		var activations_spent = 0
		
		# Check if slot preserves charges
		var should_preserve = slot.preserves_charges()
		
		# Get trigger count from slot (for Repeater slots)
		var trigger_count = slot.get_trigger_count()
		
		# Execute the activation (potentially multiple times)
		for i in range(trigger_count):
			rune.on_activate(battle_context, slot)
			# Execute slot's on-activation effects
			slot.on_rune_activation(battle_context)
			activations_spent += 1
		
		# Restore activation count if slot preserves charges
		if should_preserve:
			rune.current_activations = activations_before
		
		# Emit the slot read event with all details
		_emit_slot_read_event(coord, slot, rune, score_before, activations_before, activations_spent)
		
		# Track this activation for sequence-dependent effects (e.g., last element)
		if battle_context and activations_spent > 0:
			battle_context.record_activation(rune, slot)
			if event_bus and event_bus.has_method("notify_rune_activated"):
				event_bus.notify_rune_activated(slot, rune)


func _emit_slot_read_event(coord: Vector2i, slot: GridSlot, rune: RuneInstance, score_before: int, activations_before: int, activations_spent: int) -> void:
	if not event_bus:
		return
	
	var event = SlotReadEvent.new()
	event.phase = GameEnums.GamePhase.BATTLE
	event.slot_coord = coord
	event.rune_id = rune.data.id if rune.data.id else StringName(rune.data.rune_name)
	event.rune_elements = rune.data.elements
	event.rune_tier = rune.data.tier
	event.score_before = score_before
	event.score_after = total_score
	event.slot_multiplier = slot.get_multiplier()
	event.activations_used = activations_spent
	event.activations_remaining = rune.get_max_activations() - rune.current_activations
	event.was_empty = false
	event.was_disabled = false
	
	# Collect condition/payload results from effects
	for i in range(rune.data.effects.size()):
		var effect = rune.data.effects[i]
		if effect.condition:
			var was_met = effect.condition.evaluate(rune, battle_context, slot)
			event.conditions_evaluated.append({
				"condition_type": effect.condition.get_class(),
				"met": was_met
			})
		
		if effect.payload:
			event.payloads_executed.append({
				"payload_type": effect.payload.get_class(),
				"success": rune.last_effect_success,
				"score_delta": total_score - score_before
			})
	
	event_bus.emit(event)


func _emit_empty_slot_event(coord: Vector2i, score_before: int) -> void:
	if not event_bus:
		return
	
	var event = SlotReadEvent.new()
	event.phase = GameEnums.GamePhase.BATTLE
	event.slot_coord = coord
	event.was_empty = true
	event.score_before = score_before
	event.score_after = score_before
	
	event_bus.emit(event)


func _emit_disabled_slot_event(coord: Vector2i, rune: RuneInstance, score_before: int) -> void:
	if not event_bus:
		return
	
	var event = SlotReadEvent.new()
	event.phase = GameEnums.GamePhase.BATTLE
	event.slot_coord = coord
	event.rune_id = StringName(rune.data.id) if rune.data.id else StringName(rune.data.rune_name)
	event.rune_elements = rune.data.elements
	event.was_disabled = true
	event.score_before = score_before
	event.score_after = score_before
	
	event_bus.emit(event)


func _on_score_event(amount: int, _source: RuneInstance) -> void:
	total_score += amount
	if battle_context:
		battle_context.current_score = total_score
	score_updated.emit(total_score)


func _on_reader_jump_request(target_index: int) -> void:
	if traversal_order.is_empty():
		return
	# _process_next_step increments current_index at the end, so offset by -1
	var clamped = clamp(target_index, 0, traversal_order.size() - 1)
	current_index = clamped - 1


func _finish_sequence() -> void:
	is_running = false

	# Clear temporary buffs/states now that the round is over so tooltips don't show stale bonuses
	# Emit panel complete event
	if event_bus and event_bus.has_method("emit"):
		var panel_event = PanelCompleteEvent.new()
		panel_event.phase = GameEnums.GamePhase.BATTLE
		panel_event.panel_index = 0
		panel_event.panel_multiplier = 1.0  # TODO: Get from panel data
		panel_event.raw_score = total_score
		panel_event.final_score = total_score
		event_bus.emit(panel_event)
	
	# Notify EventBus that battle ended
	if event_bus and event_bus.has_method("end_battle"):
		# Get target score from game manager
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		var target = 0
		if game_manager:
			target = game_manager.current_target_score
		event_bus.end_battle(target)

	# Reset grid state after end-of-round effects have resolved
	if grid_manager:
		grid_manager.process_round_end()
	
	sequence_finished.emit(total_score)
	
	# Clean up context signals if needed, though RefCounted handles memory
	if battle_context:
		if battle_context.score_event.is_connected(_on_score_event):
			battle_context.score_event.disconnect(_on_score_event)
		battle_context = null


func stop_sequence() -> void:
	is_running = false
