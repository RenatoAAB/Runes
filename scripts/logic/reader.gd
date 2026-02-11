class_name Reader
extends Node

## The core game loop executor.
## Iterates through the grid sequentially and triggers runes.
## Emits events through EventBus for unified processing and recording.

const _RelicActivatedEvent = preload("res://scripts/core/events/relic_activated_event.gd")
const _InfiniteLoopEvent = preload("res://scripts/core/events/infinite_loop_event.gd")

signal step_started(coord: Vector2i)
signal step_completed(coord: Vector2i)
signal sequence_finished(total_score: int)
signal score_updated(new_total: int)
signal relic_step_started(relic_index: int, relic: RelicInstance)
signal relic_step_completed(relic_index: int, relic: RelicInstance, multiplier: float)
signal relic_processing_finished(combined_multiplier: float)

@export var grid_manager: GridManager
@export var step_delay: float = 0.5
@export var relic_step_delay: float = 0.4

var is_running: bool = false
var current_index: int = 0
var total_score: int = 0
var battle_context: BattleContext
var traversal_order: Array[Vector2i] = []

## Owning panel instance (optional, for relic processing)
var panel_instance: PanelInstance = null

## Reference to EventBus autoload (set in _ready or via export)
var event_bus: Node = null

## Infinite loop detector instance
var loop_detector: InfiniteLoopDetector = null

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
	# Share EventBus reference with context for destroy/create notifications
	battle_context.event_bus = event_bus
	
	# Initialize infinite loop detector
	loop_detector = InfiniteLoopDetector.new()
	print("[Reader] InfiniteLoopDetector initialized")
	# Analyze planning phase movements for relic stats
	if event_bus:
		var planning_events = event_bus.get("current_planning_events")
		if planning_events is Array:
			battle_context.analyze_planning_movements(planning_events, grid_manager)

	# Share references with EventBus so non-ON_READ triggers work
	if event_bus and event_bus.has_method("set_battle_references"):
		event_bus.set_battle_references(battle_context, grid_manager)

	# Build traversal order based on valid slots and share with context
	traversal_order = _build_traversal_order()
	battle_context.set_reader_path(traversal_order)
	
	# Reset grid state before starting
	grid_manager.process_round_end()
	# Execute slot round-start effects
	_execute_round_start_slot_effects()
	
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

	# Residue processing
	if grid_manager and grid_manager.residue_processor:
		if grid_manager.residue_processor.should_skip_read(slot):
			return
	
	var can_activate = rune.can_activate()
	var forced_activation = false
	if not can_activate:
		if grid_manager and grid_manager.slot_processor:
			forced_activation = grid_manager.slot_processor.should_force_activation(slot, rune)
			if forced_activation:
				can_activate = true
		elif slot.slot and slot.slot.data and slot.slot.data.id == "slot_overclocker":
			forced_activation = true
			can_activate = true

	if can_activate:
		# Set context before activation so slot multiplier can be applied
		battle_context.set_current_context(slot, rune)

		# Residue: pre-activation hooks
		var residue_snapshot := {}
		if grid_manager and grid_manager.residue_processor:
			residue_snapshot = grid_manager.residue_processor.before_activation(slot, rune)
		
		# Capture state before activation
		var activations_before = rune.current_activations
		var activations_spent = 0
		
		# Check if slot preserves charges
		var should_preserve = slot.preserves_charges()
		
		# Get trigger count from slot (for Repeater slots)
		var trigger_count = slot.get_trigger_count()
		if slot.slot and slot.slot.data and slot.slot.data.id == "slot_catalyzer":
			trigger_count = max(rune.get_max_activations() - rune.current_activations, 1)
		if forced_activation:
			trigger_count = 1
		
		# Execute the activation (potentially multiple times)
		for i in range(trigger_count):
			slot.on_before_rune_read(battle_context)
			if forced_activation:
				var original_activations = rune.current_activations
				rune.current_activations = max(rune.get_max_activations() - 1, 0)
				rune.on_activate(battle_context, slot)
				rune.current_activations = original_activations
			else:
				rune.on_activate(battle_context, slot)
			# Execute slot's on-activation effects
			slot.on_rune_activation(battle_context)
			# Residue: per-activation hooks
			if grid_manager and grid_manager.residue_processor:
				grid_manager.residue_processor.on_activation(slot, rune)
			activations_spent += 1
		
		# Restore activation count if slot preserves charges
		if should_preserve:
			rune.current_activations = activations_before
		# Residue: post-activation hooks
		if grid_manager and grid_manager.residue_processor:
			grid_manager.residue_processor.after_activation(slot, rune, residue_snapshot)
		# Overclocker: 50% chance to break if forced activation
		if forced_activation:
			var should_destroy = false
			if grid_manager and grid_manager.slot_processor:
				should_destroy = grid_manager.slot_processor.should_destroy_overclocked_rune(slot, rune, forced_activation)
			elif randf() < 0.5 and not slot.protects_fragile() and not rune.data.is_indestructible:
				should_destroy = true
			if should_destroy:
				_destroy_rune(slot, rune)
		
		# Emit the slot read event with all details
		_emit_slot_read_event(coord, slot, rune, score_before, activations_before, activations_spent)
		
		# Track this activation for sequence-dependent effects (e.g., last element)
		if battle_context and activations_spent > 0:
			battle_context.record_activation(rune, slot)
			if event_bus and event_bus.has_method("notify_rune_activated"):
				event_bus.notify_rune_activated(slot, rune)
			
			# Feed the loop detector and check for infinite loops
			if loop_detector:
				var remaining: int = rune.get_max_activations() - rune.current_activations
				var rune_id: StringName = rune.data.id if rune.data.id else StringName(rune.data.rune_name)
				loop_detector.record_activation(rune_id, coord, remaining)
				var loop_result := loop_detector.check_for_loop()
				if not loop_result.is_empty():
					_handle_infinite_loop(loop_result)


func _emit_slot_read_event(coord: Vector2i, slot: GridSlot, rune: RuneInstance, score_before: int, activations_before: int, activations_spent: int) -> void:
	if not event_bus:
		return
	
	var event = SlotReadEvent.new()
	event.phase = GameEnums.GamePhase.BATTLE
	event.slot_coord = coord
	event.rune_id = rune.data.id if rune.data.id else StringName(rune.data.rune_name)
	event.rune_elements = rune.get_elements()
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
	event.rune_elements = rune.get_elements()
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
	if battle_context:
		battle_context.record_reader_jump(clamped)
	current_index = clamped - 1


func _finish_sequence() -> void:
	is_running = false

	# Execute slot round-end effects after the last step
	_execute_round_end_slot_effects()

	var raw_score := total_score

	# Process relics after the grid has finished — one-by-one with visual delay
	var relic_multiplier := 1.0
	if panel_instance and panel_instance.attached_relics.size() > 0:
		var stats := BattleRoundStatistics.build_from(battle_context, grid_manager)
		relic_multiplier = await _process_relics_sequentially(panel_instance.attached_relics, stats)

	# Store relic multiplier on panel (calculate_final_score applies it once)
	if panel_instance:
		panel_instance.relic_multiplier = relic_multiplier
		panel_instance.current_score = raw_score

	# Compute the final score (raw * panel_multiplier which includes relic_multiplier)
	var final_score := raw_score
	if panel_instance:
		final_score = int(panel_instance.calculate_final_score())
	total_score = final_score

	# Update score label so the UI shows the final multiplied score
	score_updated.emit(total_score)

	# Emit panel complete event
	if event_bus and event_bus.has_method("emit"):
		var panel_event = PanelCompleteEvent.new()
		panel_event.phase = GameEnums.GamePhase.BATTLE
		panel_event.panel_index = panel_instance.panel_index if panel_instance else 0
		panel_event.panel_multiplier = relic_multiplier
		panel_event.raw_score = raw_score
		panel_event.final_score = total_score
		event_bus.emit(panel_event)
	
	# Notify EventBus that battle ended
	if event_bus and event_bus.has_method("end_battle"):
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


## Process relics one-by-one with visual delay between each.
## Emits relic_step_started / relic_step_completed so the UI can highlight slots.
## Returns the combined multiplier.
func _process_relics_sequentially(relics: Array, stats: BattleRoundStatistics) -> float:
	var combined: float = 1.0

	for i in range(relics.size()):
		var relic = relics[i] as RelicInstance
		if relic == null or not relic.is_active or not relic.has_calculator():
			continue

		# Signal: highlight this relic slot
		relic_step_started.emit(i, relic)

		# Calculate multiplier (updates relic.last_calculated_multiplier internally)
		var mult := relic.calculate_multiplier(stats)
		combined *= mult

		# Emit EventBus event for stats / item_ui flash
		if event_bus and event_bus.has_method("emit"):
			var relic_event = _RelicActivatedEvent.new()
			relic_event.phase = GameEnums.GamePhase.BATTLE
			relic_event.panel_index = panel_instance.panel_index if panel_instance else 0
			relic_event.relic_id = StringName(relic.data.id)
			relic_event.multiplier_value = mult
			relic_event.relic_order_index = i
			event_bus.emit(relic_event)

		# Wait for visual feedback
		await get_tree().create_timer(relic_step_delay).timeout

		# Signal: clear highlight
		relic_step_completed.emit(i, relic, mult)

	relic_processing_finished.emit(combined)
	return combined


func stop_sequence() -> void:
	is_running = false


func _destroy_rune(slot: GridSlot, rune: RuneInstance) -> void:
	if not slot or not rune:
		return
	if battle_context:
		if battle_context.event_bus:
			battle_context.event_bus.notify_rune_destroyed(slot, rune)
		else:
			battle_context.on_rune_destroyed(slot, rune)
	slot.remove_rune()
	if grid_manager:
		grid_manager.slot_changed.emit(slot.grid_position)


## Handles an infinite loop detected by the loop detector.
## Destroys (or disables) the runes in the cycle and emits an InfiniteLoopEvent.
func _handle_infinite_loop(loop_data: Dictionary) -> void:
	var cycle_slots: Array = loop_data.get("cycle_slots", [])
	var cycle_runes: Array = loop_data.get("cycle_runes", [])
	var cycle_length: int = loop_data.get("cycle_length", 0)
	var repetitions: int = loop_data.get("repetitions", 0)
	
	print("[Reader] HANDLING INFINITE LOOP: destroying %d runes" % cycle_slots.size())
	
	var runes_destroyed: Array[Dictionary] = []
	var runes_disabled: Array[Dictionary] = []
	
	# Use a set to avoid processing duplicate slots
	var processed_slots: Dictionary = {}
	
	for i in range(cycle_slots.size()):
		var slot_pos: Vector2i = cycle_slots[i]
		var rune_id: StringName = cycle_runes[i]
		
		# Skip if already processed (same slot can appear multiple times in cycle)
		if processed_slots.has(slot_pos):
			continue
		processed_slots[slot_pos] = true
		
		var slot: GridSlot = grid_manager.get_slot(slot_pos) if grid_manager else null
		if not slot or slot.is_empty():
			continue
		
		var rune: RuneInstance = slot.rune
		var entry := {"rune_id": rune_id, "slot_position": slot_pos}
		
		# Check if rune is indestructible
		if rune.data.is_indestructible:
			# Disable instead of destroy
			rune.is_disabled = true
			runes_disabled.append(entry)
			print("[Reader] Disabled indestructible rune %s at %s" % [rune_id, str(slot_pos)])
		else:
			# Destroy the rune
			print("[Reader] Destroying rune %s at %s" % [rune_id, str(slot_pos)])
			_destroy_rune(slot, rune)
			runes_destroyed.append(entry)
	
	# Update battle context
	if battle_context:
		battle_context.record_infinite_loop(loop_data)
	
	# Emit InfiniteLoopEvent
	if event_bus and event_bus.has_method("emit"):
		var loop_event = _InfiniteLoopEvent.new()
		loop_event.phase = GameEnums.GamePhase.BATTLE
		loop_event.loop_cycle_length = cycle_length
		loop_event.loop_repetitions_detected = repetitions
		loop_event.runes_destroyed = runes_destroyed
		loop_event.runes_disabled = runes_disabled
		loop_event.total_loops_this_round = battle_context.infinite_loops_detected if battle_context else 1
		event_bus.emit(loop_event)
	
	print("[Reader] Infinite loop resolved. Continuing from index %d" % (current_index + 1))


func _execute_round_start_slot_effects() -> void:
	if not grid_manager or not battle_context:
		return
	for slot in grid_manager.grid:
		if slot and not slot.is_void():
			slot.on_round_start(battle_context)


func _execute_round_end_slot_effects() -> void:
	if not grid_manager or not battle_context:
		return
	for slot in grid_manager.grid:
		if slot and not slot.is_void():
			slot.on_round_end(battle_context)
