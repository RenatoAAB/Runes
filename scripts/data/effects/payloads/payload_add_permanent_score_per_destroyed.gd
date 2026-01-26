class_name PayloadAddPermanentScorePerDestroyed
extends EffectPayload

## Grants permanent score based on runes destroyed this round.
@export var amount_per_rune: int = 0

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if amount_per_rune == 0:
		return
	var destroyed := context.runes_destroyed_this_round
	if destroyed <= 0:
		return
	apply_score(destroyed * amount_per_rune, source_rune, context, true)


func get_description() -> String:
	return "+%d permanent score per rune destroyed this round" % amount_per_rune


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.DESTROY]
