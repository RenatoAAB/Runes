class_name PayloadSkipNext
extends EffectPayload

## Skips the next slot(s) in the reader sequence.
## Uses the existing reader_jump mechanism.

@export var slots_to_skip: int = 1  ## How many slots to skip

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Jump to current + 1 (normal) + slots_to_skip
	var target_index = context.current_step_index + 1 + slots_to_skip
	context.request_reader_jump(target_index)

func get_description() -> String:
	if slots_to_skip == 1:
		return "Skip the next slot"
	return "Skip the next %d slots" % slots_to_skip

func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
