class_name PayloadAddScore
extends EffectPayload

@export var score_amount: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Decoupled implementation using BattleContext
	print("Adding Score: %d from Rune %s" % [score_amount, source_rune.data.rune_name])
	context.add_score(score_amount, source_rune)

func get_description() -> String:
	return "Adds %d Score" % score_amount
