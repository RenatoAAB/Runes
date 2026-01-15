class_name PayloadAddScore
extends EffectPayload

@export var score_amount: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	apply_score(score_amount, source_rune, context, false)

func get_description() -> String:
	return "Adds %d Score" % score_amount

func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE]
