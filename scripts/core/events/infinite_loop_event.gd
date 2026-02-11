class_name InfiniteLoopEvent
extends GameEvent

## Event emitted when an infinite loop is detected and resolved.
## Contains information about the loop cycle and the runes that were destroyed.

## Size of the detected cycle (e.g., 3 for A→B→C→A→B→C...)
var loop_cycle_length: int = 0

## Number of repetitions that were detected before breaking the loop
var loop_repetitions_detected: int = 0

## Runes that were destroyed to break the loop
## Each entry is {rune_id: StringName, slot_position: Vector2i}
var runes_destroyed: Array[Dictionary] = []

## Runes that were disabled (if indestructible) instead of destroyed
## Each entry is {rune_id: StringName, slot_position: Vector2i}
var runes_disabled: Array[Dictionary] = []

## Total number of infinite loops detected this round (cumulative)
var total_loops_this_round: int = 0


func get_event_type() -> StringName:
	return &"InfiniteLoopEvent"


func to_dict() -> Dictionary:
	var base := super.to_dict()
	base["loop_cycle_length"] = loop_cycle_length
	base["loop_repetitions_detected"] = loop_repetitions_detected
	base["runes_destroyed"] = runes_destroyed.duplicate()
	base["runes_disabled"] = runes_disabled.duplicate()
	base["total_loops_this_round"] = total_loops_this_round
	return base


func get_summary() -> String:
	var destroyed_count := runes_destroyed.size()
	var disabled_count := runes_disabled.size()
	return "[InfiniteLoopEvent] Cycle of %d runes repeated %dx. Destroyed: %d, Disabled: %d. Total loops: %d" % [
		loop_cycle_length, loop_repetitions_detected, destroyed_count, disabled_count, total_loops_this_round
	]
