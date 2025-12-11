class_name PayloadResetReader
extends EffectPayload

## Resets the reader to the beginning of the sequence.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	context.request_reader_jump(0)
	print("Time: Reset reader to beginning")

func get_description() -> String:
	return "Resets reader to beginning"
