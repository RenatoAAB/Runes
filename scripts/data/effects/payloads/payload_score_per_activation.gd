class_name PayloadScorePerActivation
extends EffectPayload

## Adds score based on the number of total activations that occurred previously.

@export var score_per_activation: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Get total activations from context
	var total_activations = context.get_meta("total_activations", 0)
	var score = total_activations * score_per_activation
	var final_score = source_rune.get_modified_score(score)
	
	context.add_score(final_score, source_rune)
	print("Memory: Added %d score for %d previous activations" % [final_score, total_activations])

func get_description() -> String:
	return "Adds %d Score × previous activations" % score_per_activation
