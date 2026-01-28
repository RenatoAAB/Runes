class_name PayloadPermanentBonusPerRuneCreated
extends EffectPayload

## Grants permanent score and activation bonuses based on runes created this round.

@export var score_per_rune: int = 20
@export var activation_per_rune: int = 1

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context or not source_rune:
		return
	var created = context.runes_created_this_round
	if created <= 0:
		return
	var total_score = score_per_rune * created
	if total_score != 0:
		apply_score(total_score, source_rune, context, true)
	var total_activation = activation_per_rune * created
	if total_activation != 0:
		source_rune.permanent_buffs["activation_bonus"] = source_rune.permanent_buffs.get("activation_bonus", 0) + total_activation


func get_description() -> String:
	return "+%d permanent score and +%d permanent activation per rune created this round" % [score_per_rune, activation_per_rune]


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.BUFF]
