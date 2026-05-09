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
	if ctx.source_slot.is_void():
		return false

	var pos = ctx.source_slot.grid_position
	var max_idx = GridManager.GRID_SIZE - 1
	var is_match = false

	match position_type:
		PositionType.CORNER:
			var bounds := _get_constructed_bounds(ctx)
			if not bounds.is_empty():
				var min_x: int = bounds["min_x"]
				var max_x: int = bounds["max_x"]
				var min_y: int = bounds["min_y"]
				var max_y: int = bounds["max_y"]
				is_match = (pos.x == min_x or pos.x == max_x) and (pos.y == min_y or pos.y == max_y)
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


func _get_constructed_bounds(ctx: EffectContext) -> Dictionary:
	var bounds := {}
	if not ctx or not ctx.battle or not ctx.battle.grid:
		return bounds

	var min_x := GridManager.GRID_SIZE
	var min_y := GridManager.GRID_SIZE
	var max_x := -1
	var max_y := -1

	for y in range(GridManager.GRID_SIZE):
		for x in range(GridManager.GRID_SIZE):
			var slot = ctx.battle.grid.get_slot(Vector2i(x, y))
			if not slot or slot.is_void():
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if max_x < 0:
		return bounds

	bounds["min_x"] = min_x
	bounds["max_x"] = max_x
	bounds["min_y"] = min_y
	bounds["max_y"] = max_y
	return bounds


func get_description() -> String:
	var pos_str = PositionType.keys()[position_type].capitalize()
	if negate:
		return "NOT on " + pos_str
	return "On " + pos_str


func get_keywords() -> Array[StringName]:
	return [Keywords.POSITION]
