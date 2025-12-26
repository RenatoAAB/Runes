class_name PayloadDecay
extends EffectPayload

## Multiplies global score and removes activations from adjacent runes.

@export var score_multiplier: float = 2.0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# First multiply the global score
	context.multiply_global_score(score_multiplier)
	
	# Then remove one activation from all adjacent runes
	for slot in targets:
		if not slot.is_empty() and slot.rune != source_rune:
			# Increase current_activations to reduce remaining
			slot.rune.current_activations += 1
			print("Decay: Removed 1 activation from %s" % slot.rune.data.rune_name)

func get_description() -> String:
	return "Multiplies score by %.1f, adjacent runes lose 1 activation" % score_multiplier

func get_keywords() -> Array[StringName]:
	return [Keywords.DECAYING, Keywords.MULTIPLY, Keywords.NEIGHBORS]
