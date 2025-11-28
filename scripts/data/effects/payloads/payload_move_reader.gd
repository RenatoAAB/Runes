class_name PayloadMoveReader
extends EffectPayload

enum MoveType {
	START_OF_ROW,
	REWIND_STEPS
}

@export var move_type: MoveType = MoveType.START_OF_ROW
@export var steps: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var current = context.current_step_index
	var target_idx = current
	
	match move_type:
		MoveType.START_OF_ROW:
			var y = current / GridManager.GRID_SIZE
			target_idx = y * GridManager.GRID_SIZE
		MoveType.REWIND_STEPS:
			target_idx = current - steps
			
	context.request_reader_jump(target_idx)

func get_description() -> String:
	match move_type:
		MoveType.START_OF_ROW: return "Reader jumps to Row Start"
		MoveType.REWIND_STEPS: return "Reader rewinds %d steps" % steps
	return ""
