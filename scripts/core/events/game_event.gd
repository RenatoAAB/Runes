## Base class for all game events.
## Events are the atomic unit of gameplay - used for both processing AND recording.
## Every meaningful action in the game flows through an event.
class_name GameEvent
extends RefCounted

## Unique identifier for this event instance
var id: int

## Timestamp when the event was created (msec since game start)
var timestamp_msec: int

## The game phase when this event occurred
var phase: GameEnums.GamePhase

## Whether this event has been processed by the game logic
var processed: bool = false

## Whether this event was successful (set after processing)
var success: bool = true

## Optional error/cancel reason if success is false
var failure_reason: String = ""

## Static counter for unique IDs
static var _next_id: int = 0


func _init() -> void:
	id = _next_id
	_next_id += 1
	timestamp_msec = Time.get_ticks_msec()


## Returns the event type as a StringName for filtering/routing
func get_event_type() -> StringName:
	return &"GameEvent"


## Serializes the event to a Dictionary for persistence/debugging
func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": get_event_type(),
		"timestamp_msec": timestamp_msec,
		"phase": phase,
		"processed": processed,
		"success": success,
		"failure_reason": failure_reason,
	}


## Creates an event from a serialized Dictionary
static func from_dict(_data: Dictionary) -> GameEvent:
	# Override in subclasses for proper deserialization
	push_error("GameEvent.from_dict() must be overridden in subclass")
	return null


## Returns a human-readable summary of the event for debugging
func get_summary() -> String:
	return "[%s] Event #%d" % [get_event_type(), id]
