class_name PayloadPermanentScoreFromHistory
extends EffectPayload

## Scales permanent score with previous activations in the round.
@export var per_activation: int = 1
@export var per_unique_rune: int = -1

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var activations := context.get_total_activations_this_round()
	var unique_runes := context.get_unique_runes_count()
	var total := activations * per_activation + unique_runes * per_unique_rune
	if total == 0:
		return
	apply_score(total, source_rune, context, true)


func get_description() -> String:
	return "+%d permanent score per prior activation, %d per unique rune" % [per_activation, per_unique_rune]


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.SEQUENCE, Keywords.SCALING]
