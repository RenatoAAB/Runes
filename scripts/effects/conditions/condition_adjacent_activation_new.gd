class_name ConditionAdjacentActivationNew
extends NewEffectCondition

## True if the last activation was from an adjacent rune with required element(s).

@export var required_elements: Array[GameEnums.Element] = []
@export var include_diagonals: bool = false


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.source_slot or not ctx.battle or not ctx.battle.grid:
		return false

	if ctx.battle.activation_history.is_empty():
		return false

	var last = ctx.battle.activation_history[-1]
	var activated_pos: Vector2i = last.get("slot_position", Vector2i(-1, -1))
	if not ctx.battle.grid.is_valid_coord(activated_pos):
		return false

	var neighbors = ctx.battle.grid.get_neighbors(ctx.source_slot.grid_position, include_diagonals)
	var is_adjacent = false
	for slot in neighbors:
		if slot.grid_position == activated_pos:
			is_adjacent = true
			break
	if not is_adjacent:
		EffectLogger.log_condition(ctx, self, false)
		return false

	var elements: Array[GameEnums.Element] = last.get("elements", [])
	if required_elements.is_empty():
		EffectLogger.log_condition(ctx, self, true)
		return true

	for elem in elements:
		if elem in required_elements:
			EffectLogger.log_condition(ctx, self, true)
			return true

	EffectLogger.log_condition(ctx, self, false)
	return false


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle or ctx.battle.activation_history.is_empty():
		return []
	var last = ctx.battle.activation_history[-1]
	var pos: Vector2i = last.get("slot_position", Vector2i(-1, -1))
	if not ctx.battle.grid.is_valid_coord(pos):
		return []
	return [ctx.battle.grid.get_slot(pos)]


func get_description() -> String:
	var diag_str = " (incl. diag)" if include_diagonals else ""
	var elems_str = ElementIcons.join(required_elements)
	if elems_str.is_empty():
		elems_str = "rune"
	return "adjacent %s activation%s" % [elems_str, diag_str]


func get_keywords() -> Array[StringName]:
	return [Keywords.ADJACENT, Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
