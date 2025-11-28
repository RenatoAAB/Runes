class_name PayloadAddScore
extends EffectPayload

@export var score_amount: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Decoupled implementation using BattleContext
	# Apply modifiers from source rune
	var final_score = source_rune.get_modified_score(score_amount)
	
	print("Adding Score: %d (Base: %d) from Rune %s" % [final_score, score_amount, source_rune.data.rune_name])
	context.add_score(final_score, source_rune)

func get_description() -> String:
	return "Adds %d Score" % score_amount
