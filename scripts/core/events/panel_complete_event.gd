## Event emitted when a panel (grid) completes its processing.
## Contains aggregated results from all slot reads in this panel.
class_name PanelCompleteEvent
extends GameEvent

## The panel's identifier (for multi-panel support)
var panel_id: int = 0

## The panel's index in the chain (0 = first panel)
var panel_index: int = 0

## Total score from this panel before panel multiplier
var raw_score: int = 0

## The panel's global multiplier
var panel_multiplier: float = 1.0

## Total score after panel multiplier
var final_score: int = 0

## Score received from the previous panel (chaining)
var incoming_score: int = 0

## All slot read events that occurred in this panel
var slot_events: Array[SlotReadEvent] = []

## Number of runes that were activated
var runes_activated: int = 0

## Number of slots that were empty
var empty_slots: int = 0

## Number of runes that were disabled
var disabled_runes: int = 0

## Synergy bonuses applied (geometry, content, etc.)
## Array of { "type": StringName, "description": String, "bonus": float }
var synergies_applied: Array[Dictionary] = []

## Aggregated keyword statistics for this panel
## Dictionary of keyword_id -> count
var keyword_counts: Dictionary = {}


func _init() -> void:
	super._init()


func get_event_type() -> StringName:
	return &"PanelCompleteEvent"


## Calculate aggregated statistics from slot events
func aggregate_from_slots() -> void:
	raw_score = 0
	runes_activated = 0
	empty_slots = 0
	disabled_runes = 0
	keyword_counts.clear()
	
	for event in slot_events:
		if event.was_empty:
			empty_slots += 1
		elif event.was_disabled:
			disabled_runes += 1
		else:
			runes_activated += 1
			raw_score += event.get_score_delta()
			
			# Aggregate keywords
			for kw in event.keywords_triggered:
				if kw in keyword_counts:
					keyword_counts[kw] += 1
				else:
					keyword_counts[kw] = 1
	
	# Apply panel multiplier
	final_score = int(raw_score * panel_multiplier)


## Get the total score contribution (including incoming from chain)
func get_total_contribution() -> int:
	return final_score + incoming_score


func to_dict() -> Dictionary:
	var base = super.to_dict()
	base.merge({
		"panel_id": panel_id,
		"panel_index": panel_index,
		"raw_score": raw_score,
		"panel_multiplier": panel_multiplier,
		"final_score": final_score,
		"incoming_score": incoming_score,
		"total_contribution": get_total_contribution(),
		"runes_activated": runes_activated,
		"empty_slots": empty_slots,
		"disabled_runes": disabled_runes,
		"synergies_applied": synergies_applied,
		"keyword_counts": keyword_counts,
		"slot_event_count": slot_events.size(),
	})
	return base


func get_summary() -> String:
	return "[PanelComplete] Panel %d - %d pts (raw: %d x%.2f) | %d runes activated" % [
		panel_index, final_score, raw_score, panel_multiplier, runes_activated
	]
