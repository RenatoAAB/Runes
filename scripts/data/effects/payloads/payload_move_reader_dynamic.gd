class_name PayloadMoveReaderDynamic
extends EffectPayload

## Moves the reader dynamically based on various conditions.
## Flexible payload for: Ar, Vento, Som, Tempo, Djinn, Instabilidade.

enum MoveMode {
	FIXED_STEPS,            ## Move back a fixed number of steps
	STEPS_PER_ADJACENT,     ## Move back N steps per adjacent rune
	STEPS_PER_REMAINING,    ## Move back N steps per remaining activation (self)
	TO_PREVIOUS_ELEMENT,    ## Jump to last rune of specific element
	TO_RANDOM_VISITED,      ## Jump to random previously visited slot
	TO_SLOT_ABOVE,          ## Jump to slot directly above (lower index in same column)
	TO_SLOT_BELOW,          ## Jump to slot directly below (higher index in same column)
	CONDITIONAL_UP_DOWN     ## Choice: go up or down based on condition
}

@export var mode: MoveMode = MoveMode.FIXED_STEPS
@export var steps: int = 1
@export var target_element: GameEnums.Element = GameEnums.Element.FIRE
@export var include_diagonals: bool = false

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var current_idx = context.current_step_index
	var target_idx = -1
	
	match mode:
		MoveMode.FIXED_STEPS:
			target_idx = current_idx - steps
		
		MoveMode.STEPS_PER_ADJACENT:
			var neighbors = context.grid.get_neighbors(context.current_slot.grid_position, include_diagonals)
			var adjacent_count = 0
			for slot in neighbors:
				if not slot.is_empty():
					adjacent_count += 1
			target_idx = current_idx - (steps * adjacent_count)
		
		MoveMode.STEPS_PER_REMAINING:
			var remaining = source_rune.get_max_activations() - source_rune.current_activations
			target_idx = current_idx - (steps * remaining)
		
		MoveMode.TO_PREVIOUS_ELEMENT:
			target_idx = _find_previous_element(context, current_idx)
		
		MoveMode.TO_RANDOM_VISITED:
			target_idx = context.get_random_visited_slot()
		
		MoveMode.TO_SLOT_ABOVE:
			var pos = context.current_slot.grid_position
			if pos.y > 0:
				var above_pos = Vector2i(pos.x, pos.y - 1)
				target_idx = above_pos.y * GridManager.GRID_SIZE + above_pos.x
		
		MoveMode.TO_SLOT_BELOW:
			var pos = context.current_slot.grid_position
			if pos.y < GridManager.GRID_SIZE - 1:
				var below_pos = Vector2i(pos.x, pos.y + 1)
				target_idx = below_pos.y * GridManager.GRID_SIZE + below_pos.x
		
		MoveMode.CONDITIONAL_UP_DOWN:
			# Default to moving down, conditions can override
			var pos = context.current_slot.grid_position
			if pos.y < GridManager.GRID_SIZE - 1:
				var below_pos = Vector2i(pos.x, pos.y + 1)
				target_idx = below_pos.y * GridManager.GRID_SIZE + below_pos.x
	
	if target_idx >= 0 and target_idx < GridManager.GRID_SIZE * GridManager.GRID_SIZE:
		context.request_reader_jump(target_idx)
		print("%s: Reader jumping to index %d" % [source_rune.data.rune_name, target_idx])
	else:
		print("%s: Invalid reader jump target %d" % [source_rune.data.rune_name, target_idx])


func _find_previous_element(context: BattleContext, current_index: int) -> int:
	for i in range(current_index - 1, -1, -1):
		if i < context.grid.grid.size():
			var slot = context.grid.grid[i]
			if not slot.is_empty():
				if target_element in slot.rune.data.elements:
					return i
	return -1


func get_description() -> String:
	match mode:
		MoveMode.FIXED_STEPS:
			return "Reader rewinds %d step(s)" % steps
		MoveMode.STEPS_PER_ADJACENT:
			return "Reader rewinds %d step(s) per adjacent rune" % steps
		MoveMode.STEPS_PER_REMAINING:
			return "Reader rewinds %d step(s) per remaining activation" % steps
		MoveMode.TO_PREVIOUS_ELEMENT:
			var elem_name = GameEnums.Element.keys()[target_element].capitalize()
			return "Reader jumps to previous %s rune" % elem_name
		MoveMode.TO_RANDOM_VISITED:
			return "Reader jumps to random visited slot"
		MoveMode.TO_SLOT_ABOVE:
			return "Reader can jump to slot above"
		MoveMode.TO_SLOT_BELOW:
			return "Reader can jump to slot below"
		MoveMode.CONDITIONAL_UP_DOWN:
			return "Reader can move up or down"
	return "Reader moves"


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
