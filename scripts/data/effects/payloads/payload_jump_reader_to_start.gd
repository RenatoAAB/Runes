class_name PayloadJumpReaderToStart
extends EffectPayload

## Forces the reader to jump to the first slot in the traversal.

func execute(_targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if not context:
		return
	context.request_reader_jump(0)


func get_description() -> String:
	return "Reader returns to the start of the panel"


func get_keywords() -> Array[StringName]:
	return [Keywords.MOVE]
