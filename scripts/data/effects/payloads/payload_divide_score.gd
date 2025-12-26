class_name PayloadDivideScore
extends EffectPayload

## Freezes the current score, divides it by a factor, and starts a new score.
## At the end, the final score is multiplied by the frozen score to get the final result.

@export var divisor: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Store the frozen score in context for later multiplication
	var frozen_score = context.current_score / divisor
	if frozen_score < 1:
		frozen_score = 1
	
	# Store in context for score finalization
	if not context.has_meta("frozen_score_multiplier"):
		context.set_meta("frozen_score_multiplier", frozen_score)
		# Reset current score to 0 for new accumulation
		# We subtract the current score to set it to 0
		context.current_score = 0
		print("Dimensional: Froze score at %d (divided from %d), new score starts from 0" % [frozen_score, frozen_score * divisor])
	else:
		# Stack frozen scores by multiplying
		var current_frozen = context.get_meta("frozen_score_multiplier")
		context.set_meta("frozen_score_multiplier", current_frozen * frozen_score)
		context.current_score = 0
		print("Dimensional: Stacked frozen score multiplier to %d" % (current_frozen * frozen_score))

func get_description() -> String:
	return "Freezes score (÷%d), starts new score to multiply" % divisor

func get_keywords() -> Array[StringName]:
	return [Keywords.META, Keywords.MULTIPLY]
