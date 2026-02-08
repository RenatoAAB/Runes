## Event emitted when a relic is processed after a panel finishes.
class_name RelicActivatedEvent
extends GameEvent

## The panel index where the relic is attached
var panel_index: int = 0

## The relic ID
var relic_id: StringName = &""

## The multiplier contributed by this relic
var multiplier_value: float = 1.0

## The order index of the relic on the panel
var relic_order_index: int = 0

func _init() -> void:
	super._init()


func get_event_type() -> StringName:
	return &"RelicActivatedEvent"


func to_dict() -> Dictionary:
	var base = super.to_dict()
	base.merge({
		"panel_index": panel_index,
		"relic_id": relic_id,
		"multiplier_value": multiplier_value,
		"relic_order_index": relic_order_index,
	})
	return base


func get_summary() -> String:
	return "[RelicActivated] Panel %d | %s ×%.2f" % [panel_index, relic_id, multiplier_value]
