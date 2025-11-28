class_name ConditionGridPosition
extends EffectCondition

enum PositionType {
	CORNER,
	EDGE,
	CENTER,
	INNER_RING
}

@export var position_type: PositionType = PositionType.CORNER
@export var negate: bool = false

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var pos = source_slot.grid_position
	var size = GridManager.GRID_SIZE # 5
	var max_idx = size - 1
	
	var is_match = false
	
	match position_type:
		PositionType.CORNER:
			is_match = (pos.x == 0 or pos.x == max_idx) and (pos.y == 0 or pos.y == max_idx)
		PositionType.EDGE:
			is_match = pos.x == 0 or pos.x == max_idx or pos.y == 0 or pos.y == max_idx
		PositionType.CENTER:
			var center = size / 2 # 2 for size 5
			is_match = pos.x == center and pos.y == center
		PositionType.INNER_RING:
			# Not edge, not center
			var center = size / 2
			var is_edge = pos.x == 0 or pos.x == max_idx or pos.y == 0 or pos.y == max_idx
			var is_center = pos.x == center and pos.y == center
			is_match = not is_edge and not is_center
			
	if negate:
		return not is_match
	return is_match

func get_description() -> String:
	var pos_str = PositionType.keys()[position_type].capitalize()
	if negate:
		return "NOT on " + pos_str
	return "On " + pos_str
