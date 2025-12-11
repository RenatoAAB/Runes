class_name PayloadRandomMoveReader
extends EffectPayload

## Moves the reader forward or backward by a random amount.

@export var max_steps: int = 2

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var direction = 1 if randf() > 0.5 else -1
	var steps = randi_range(1, max_steps)
	var move = direction * steps
	
	var target_idx = context.current_step_index + move
	# Clamp to valid range
	target_idx = clamp(target_idx, 0, GridManager.GRID_SIZE * GridManager.GRID_SIZE - 1)
	
	context.request_reader_jump(target_idx)
	print("Chaos: Moved reader %s%d steps to index %d" % ["+" if direction > 0 else "", move, target_idx])

func get_description() -> String:
	return "Moves reader ±%d steps randomly" % max_steps
