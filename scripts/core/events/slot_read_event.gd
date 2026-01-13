## Event emitted when the Reader processes a slot.
## This is the atomic unit of battle gameplay - contains all information about
## what happened when a rune was activated (or attempted to activate).
class_name SlotReadEvent
extends GameEvent

## The coordinate of the slot being read
var slot_coord: Vector2i

## The rune that was in the slot (null if empty)
var rune_id: StringName

## The rune's base elements (for statistics)
var rune_elements: Array[GameEnums.Element] = []

## The rune's tier
var rune_tier: GameEnums.Tier

## Results from evaluating each condition
## Array of { "condition_type": StringName, "met": bool }
var conditions_evaluated: Array[Dictionary] = []

## The target slots that were selected
var targets_selected: Array[Vector2i] = []

## Results from executing each payload
## Array of { "payload_type": StringName, "score_delta": int, "success": bool, "details": Dictionary }
var payloads_executed: Array[Dictionary] = []

## Score before this slot was processed
var score_before: int = 0

## Score after this slot was processed
var score_after: int = 0

## The slot's multiplier applied to this activation
var slot_multiplier: float = 1.0

## How many activations were used
var activations_used: int = 0

## How many activations remain after this read
var activations_remaining: int = 0

## Whether the slot was empty (no rune)
var was_empty: bool = false

## Whether the rune was disabled and couldn't activate
var was_disabled: bool = false

func _init() -> void:
	super._init()


func get_event_type() -> StringName:
	return &"SlotReadEvent"


## Convenience: total score gained/lost in this read
func get_score_delta() -> int:
	return score_after - score_before


## Convenience: check if any payload executed successfully
func had_successful_payload() -> bool:
	for payload in payloads_executed:
		if payload.get("success", false):
			return true
	return false


## Convenience: check if all conditions were met
func all_conditions_met() -> bool:
	for condition in conditions_evaluated:
		if not condition.get("met", false):
			return false
	return true


func to_dict() -> Dictionary:
	var base = super.to_dict()
	base.merge({
		"slot_coord": {"x": slot_coord.x, "y": slot_coord.y},
		"rune_id": rune_id,
		"rune_elements": rune_elements,
		"rune_tier": rune_tier,
		"conditions_evaluated": conditions_evaluated,
		"targets_selected": targets_selected.map(func(v): return {"x": v.x, "y": v.y}),
		"payloads_executed": payloads_executed,
		"score_before": score_before,
		"score_after": score_after,
		"score_delta": get_score_delta(),
		"slot_multiplier": slot_multiplier,
		"activations_used": activations_used,
		"activations_remaining": activations_remaining,
		"was_empty": was_empty,
		"was_disabled": was_disabled,
	})
	return base


func get_summary() -> String:
	if was_empty:
		return "[SlotRead] (%d,%d) Empty" % [slot_coord.x, slot_coord.y]
	elif was_disabled:
		return "[SlotRead] (%d,%d) %s - Disabled" % [slot_coord.x, slot_coord.y, rune_id]
	else:
		var delta_str = "+%d" % get_score_delta() if get_score_delta() >= 0 else "%d" % get_score_delta()
		return "[SlotRead] (%d,%d) %s - %s pts (x%.2f)" % [slot_coord.x, slot_coord.y, rune_id, delta_str, slot_multiplier]
