## Event emitted when the player performs an action during the PLANNING phase.
## Covers all grid/inventory manipulation: placing, moving, swapping, upgrading runes.
class_name PlanningEvent
extends GameEvent

## Types of planning actions
enum ActionType {
	PLACE_RUNE,      ## Rune moved from inventory to grid
	REMOVE_RUNE,     ## Rune moved from grid to inventory
	MOVE_RUNE,       ## Rune moved within grid
	SWAP_RUNES,      ## Two runes swapped positions (grid-grid or grid-inventory)
	UPGRADE_RUNE,    ## Rune was upgraded to next tier
	ROTATE_RUNES,    ## Runes rotated in a pattern
}

## The type of action performed
var action_type: ActionType

## The rune(s) involved (by ID)
var rune_ids: Array[StringName] = []

## Source location (Vector2i for grid, or "inventory" string)
var source_location: Variant

## Destination location (Vector2i for grid, or "inventory" string)
var destination_location: Variant

## For swaps: the second rune's original location
var swap_source: Variant = null

## For upgrades: the new rune data ID
var upgraded_to: StringName = &""

## Whether the action was successful
var action_success: bool = true

## Reason for failure if not successful
var action_failure_reason: String = ""


func _init() -> void:
	super._init()
	phase = GameEnums.GamePhase.PLANNING


func get_event_type() -> StringName:
	return &"PlanningEvent"


## Factory method for PLACE_RUNE
static func create_place(rune_id: StringName, dest_coord: Vector2i) -> PlanningEvent:
	var event = PlanningEvent.new()
	event.action_type = ActionType.PLACE_RUNE
	event.rune_ids = [rune_id]
	event.source_location = "inventory"
	event.destination_location = dest_coord
	return event


## Factory method for REMOVE_RUNE
static func create_remove(rune_id: StringName, source_coord: Vector2i) -> PlanningEvent:
	var event = PlanningEvent.new()
	event.action_type = ActionType.REMOVE_RUNE
	event.rune_ids = [rune_id]
	event.source_location = source_coord
	event.destination_location = "inventory"
	return event


## Factory method for MOVE_RUNE (grid to grid)
static func create_move(rune_id: StringName, from_coord: Vector2i, to_coord: Vector2i) -> PlanningEvent:
	var event = PlanningEvent.new()
	event.action_type = ActionType.MOVE_RUNE
	event.rune_ids = [rune_id]
	event.source_location = from_coord
	event.destination_location = to_coord
	return event


## Factory method for SWAP_RUNES
static func create_swap(rune_id_a: StringName, loc_a: Variant, rune_id_b: StringName, loc_b: Variant) -> PlanningEvent:
	var event = PlanningEvent.new()
	event.action_type = ActionType.SWAP_RUNES
	event.rune_ids = [rune_id_a, rune_id_b]
	event.source_location = loc_a
	event.destination_location = loc_b
	event.swap_source = loc_b  # Original location of second rune
	return event


## Factory method for UPGRADE_RUNE
static func create_upgrade(rune_id: StringName, new_rune_id: StringName, location: Variant) -> PlanningEvent:
	var event = PlanningEvent.new()
	event.action_type = ActionType.UPGRADE_RUNE
	event.rune_ids = [rune_id]
	event.source_location = location
	event.destination_location = location
	event.upgraded_to = new_rune_id
	return event


func _location_to_string(loc: Variant) -> String:
	if loc is Vector2i:
		return "(%d,%d)" % [loc.x, loc.y]
	elif loc is String:
		return loc
	else:
		return str(loc)


func to_dict() -> Dictionary:
	var base = super.to_dict()
	base.merge({
		"action_type": ActionType.keys()[action_type],
		"rune_ids": rune_ids,
		"source_location": _location_to_string(source_location),
		"destination_location": _location_to_string(destination_location),
		"swap_source": _location_to_string(swap_source) if swap_source != null else null,
		"upgraded_to": upgraded_to,
		"action_success": action_success,
		"action_failure_reason": action_failure_reason,
	})
	return base


func get_summary() -> String:
	var rune_str = ", ".join(rune_ids.map(func(r): return str(r)))
	match action_type:
		ActionType.PLACE_RUNE:
			return "[Planning] PLACE %s → %s" % [rune_str, _location_to_string(destination_location)]
		ActionType.REMOVE_RUNE:
			return "[Planning] REMOVE %s ← %s" % [rune_str, _location_to_string(source_location)]
		ActionType.MOVE_RUNE:
			return "[Planning] MOVE %s: %s → %s" % [rune_str, _location_to_string(source_location), _location_to_string(destination_location)]
		ActionType.SWAP_RUNES:
			return "[Planning] SWAP %s ↔ %s" % [_location_to_string(source_location), _location_to_string(destination_location)]
		ActionType.UPGRADE_RUNE:
			return "[Planning] UPGRADE %s → %s" % [rune_str, upgraded_to]
		ActionType.ROTATE_RUNES:
			return "[Planning] ROTATE %s" % [rune_str]
		_:
			return "[Planning] Unknown action"
