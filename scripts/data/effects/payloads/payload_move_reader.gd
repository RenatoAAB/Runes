class_name PayloadMoveReader
extends EffectPayload

enum MoveType {
	START_OF_ROW,
	REWIND_STEPS,
	REWIND_TO_ELEMENT
}

@export var move_type: MoveType = MoveType.START_OF_ROW
@export var steps: int = 1
@export var target_element: GameEnums.Element = GameEnums.Element.FIRE
@export var fallback_type: MoveType = MoveType.START_OF_ROW

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var current = context.current_step_index
	var target_idx = -1
	
	if move_type == MoveType.REWIND_TO_ELEMENT:
		target_idx = _find_previous_element(context, current)
		if target_idx == -1:
			# Fallback
			target_idx = _calculate_target(fallback_type, current)
	else:
		target_idx = _calculate_target(move_type, current)
			
	context.request_reader_jump(target_idx)

func _find_previous_element(context: BattleContext, current_index: int) -> int:
	# Search backwards from current_index - 1
	for i in range(current_index - 1, -1, -1):
		# We need to access the grid safely. BattleContext has grid (GridManager).
		# GridManager has 'grid' array which is 1D.
		if i < context.grid.grid.size():
			var slot = context.grid.grid[i]
			if not slot.is_empty() and slot.rune.data.element == target_element:
				return i
	return -1

func _calculate_target(type: MoveType, current: int) -> int:
	match type:
		MoveType.START_OF_ROW:
			var y = current / GridManager.GRID_SIZE
			return y * GridManager.GRID_SIZE
		MoveType.REWIND_STEPS:
			return current - steps
		_:
			return current

func get_description() -> String:
	match move_type:
		MoveType.START_OF_ROW: return "Reader jumps to Row Start"
		MoveType.REWIND_STEPS: return "Reader rewinds %d steps" % steps
		MoveType.REWIND_TO_ELEMENT:
			var elem_str = GameEnums.Element.keys()[target_element].capitalize()
			return "Rewind to last %s rune" % elem_str
	return ""

func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
