## Central event bus for the game.
## All gameplay events flow through here for processing AND recording.
## This is an Autoload - add to Project Settings > Autoload as "EventBus".
extends Node

# =============================================================================
# SIGNALS - UI and other systems subscribe to these
# =============================================================================

## Emitted for every event (for debugging/logging)
signal event_emitted(event: GameEvent)

## Emitted when a slot is read during battle
signal slot_read(event: SlotReadEvent)

## Emitted when a panel completes processing
signal panel_completed(event: PanelCompleteEvent)

## Emitted when a planning action occurs
signal planning_action(event: PlanningEvent)

## Emitted when an economy transaction occurs
signal economy_transaction(event: EconomyEvent)

## Emitted when the battle sequence starts
signal battle_started(panel_count: int)

## Emitted when the battle sequence ends
signal battle_ended(total_score: int, target_score: int, victory: bool)

# =============================================================================
# STATE - Current battle/round tracking
# =============================================================================

## All events from the current battle sequence
var current_battle_events: Array[GameEvent] = []

## All planning events from the current planning phase
var current_planning_events: Array[PlanningEvent] = []

## Slot events for the current panel being processed
var current_panel_slot_events: Array[SlotReadEvent] = []

## Current accumulated score
var current_score: int = 0

## Current money (economy)
var current_money: int = 0

## Whether a battle is in progress
var is_battle_active: bool = false

## The current panel index being processed
var current_panel_index: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[EventBus] Initialized")


## Call at the start of a new battle sequence
func begin_battle(panel_count: int = 1) -> void:
	current_battle_events.clear()
	current_panel_slot_events.clear()
	current_score = 0
	current_panel_index = 0
	is_battle_active = true
	battle_started.emit(panel_count)
	print("[EventBus] Battle started with %d panel(s)" % panel_count)


## Call at the end of a battle sequence
func end_battle(target_score: int) -> void:
	is_battle_active = false
	var victory = current_score >= target_score
	battle_ended.emit(current_score, target_score, victory)
	print("[EventBus] Battle ended. Score: %d/%d - %s" % [
		current_score, target_score, "Victory!" if victory else "Defeat"
	])


## Call at the start of a planning phase
func begin_planning() -> void:
	current_planning_events.clear()
	print("[EventBus] Planning phase started")


## Call when starting to process a new panel
func begin_panel(panel_index: int) -> void:
	current_panel_index = panel_index
	current_panel_slot_events.clear()
	print("[EventBus] Processing panel %d" % panel_index)


# =============================================================================
# EVENT EMISSION - The main entry points
# =============================================================================

## Emit any event (routes to specific handlers)
func emit(event: GameEvent) -> void:
	event.processed = true
	current_battle_events.append(event)
	event_emitted.emit(event)
	
	# Route to specific signal
	if event is SlotReadEvent:
		_handle_slot_read(event as SlotReadEvent)
	elif event is PanelCompleteEvent:
		_handle_panel_complete(event as PanelCompleteEvent)
	elif event is PlanningEvent:
		_handle_planning_action(event as PlanningEvent)
	elif event is EconomyEvent:
		_handle_economy_transaction(event as EconomyEvent)


## Convenience: emit a slot read event
func emit_slot_read(event: SlotReadEvent) -> void:
	emit(event)


## Convenience: emit a planning event
func emit_planning(event: PlanningEvent) -> void:
	emit(event)


## Convenience: emit an economy event
func emit_economy(event: EconomyEvent) -> void:
	emit(event)


# =============================================================================
# EVENT HANDLERS - Process events and update state
# =============================================================================

func _handle_slot_read(event: SlotReadEvent) -> void:
	# Aggregate keywords
	event.aggregate_keywords()
	
	# Update score
	current_score = event.score_after
	
	# Track for panel aggregation
	current_panel_slot_events.append(event)
	
	# Emit specific signal
	slot_read.emit(event)
	
	# Debug output
	if OS.is_debug_build():
		print("  %s" % event.get_summary())


func _handle_panel_complete(event: PanelCompleteEvent) -> void:
	# Copy slot events to the panel event
	event.slot_events = current_panel_slot_events.duplicate()
	event.aggregate_from_slots()
	
	# Update total score
	current_score = event.get_total_contribution()
	
	# Emit specific signal
	panel_completed.emit(event)
	
	# Debug output
	if OS.is_debug_build():
		print(event.get_summary())


func _handle_planning_action(event: PlanningEvent) -> void:
	current_planning_events.append(event)
	planning_action.emit(event)
	
	# Debug output
	if OS.is_debug_build():
		print(event.get_summary())


func _handle_economy_transaction(event: EconomyEvent) -> void:
	# Update money tracking
	current_money = event.balance_after
	
	economy_transaction.emit(event)
	
	# Debug output
	if OS.is_debug_build():
		print(event.get_summary())


# =============================================================================
# QUERY METHODS - For statistics and conditions
# =============================================================================

## Get all slot reads for a specific rune ID in current battle
func get_slot_reads_for_rune(rune_id: StringName) -> Array[SlotReadEvent]:
	var result: Array[SlotReadEvent] = []
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			if sre.rune_id == rune_id:
				result.append(sre)
	return result


## Get total activations for an element in current battle
func get_activations_for_element(element: GameEnums.Element) -> int:
	var count = 0
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			if sre.rune_element == element and not sre.was_empty and not sre.was_disabled:
				count += sre.activations_used
	return count


## Get total activations in current battle
func get_total_activations() -> int:
	var count = 0
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			if not sre.was_empty and not sre.was_disabled:
				count += sre.activations_used
	return count


## Get how many times a keyword was triggered in current battle
func get_keyword_count(keyword: StringName) -> int:
	var count = 0
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			count += sre.keywords_triggered.count(keyword)
	return count


## Get score contributed by a specific rune in current battle
func get_score_for_rune(rune_id: StringName) -> int:
	var total = 0
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			if sre.rune_id == rune_id:
				total += sre.get_score_delta()
	return total


## Get the last N slot read events
func get_recent_slot_reads(count: int) -> Array[SlotReadEvent]:
	var result: Array[SlotReadEvent] = []
	var slot_events: Array[SlotReadEvent] = []
	
	for event in current_battle_events:
		if event is SlotReadEvent:
			slot_events.append(event as SlotReadEvent)
	
	var start_idx = maxi(0, slot_events.size() - count)
	for i in range(start_idx, slot_events.size()):
		result.append(slot_events[i])
	
	return result


## Check if a specific rune was activated at a specific position
func was_rune_activated_at(rune_id: StringName, coord: Vector2i) -> bool:
	for event in current_battle_events:
		if event is SlotReadEvent:
			var sre = event as SlotReadEvent
			if sre.rune_id == rune_id and sre.slot_coord == coord:
				if not sre.was_disabled and sre.had_successful_payload():
					return true
	return false
