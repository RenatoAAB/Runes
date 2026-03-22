class_name ConditionGridPositionNew
extends NewEffectCondition

## True if source slot is at a specific grid position type (corner, edge, center, inner ring).

enum PositionType {
	CORNER,
	EDGE,
	CENTER,
	INNER_RING
}

@export var position_type: PositionType = PositionType.CORNER
@export var negate: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot:
		return false

	var pos = ctx.source_slot.grid_position
	var max_idx = GridManager.GRID_SIZE - 1
	var is_match = false

	match position_type:
		PositionType.CORNER:
			is_match = (pos.x == 0 or pos.x == max_idx) and (pos.y == 0 or pos.y == max_idx)
		PositionType.EDGE:
			is_match = pos.x == 0 or pos.x == max_idx or pos.y == 0 or pos.y == max_idx
		PositionType.CENTER:
			var center = GridManager.GRID_SIZE / 2
			is_match = pos.x == center and pos.y == center
		PositionType.INNER_RING:
			var center = GridManager.GRID_SIZE / 2
			var is_edge = pos.x == 0 or pos.x == max_idx or pos.y == 0 or pos.y == max_idx
			var is_center = pos.x == center and pos.y == center
			is_match = not is_edge and not is_center

	var result = not is_match if negate else is_match
	EffectLogger.log_condition(ctx, self, result)
	return result


func get_description() -> String:
	var pos_str = PositionType.keys()[position_type].capitalize()
	if negate:
		return "NOT on " + pos_str
	return "On " + pos_str


func get_keywords() -> Array[StringName]:
	return [Keywords.POSITION]
