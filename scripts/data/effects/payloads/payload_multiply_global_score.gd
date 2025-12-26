class_name PayloadMultiplyGlobalScore
extends EffectPayload

@export var multiplier: float = 2.0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	context.multiply_global_score(multiplier)

func get_description() -> String:
	return "Multiplies Total Score by %.1f" % multiplier

func get_keywords() -> Array[StringName]:
	return [Keywords.MULTIPLY]
