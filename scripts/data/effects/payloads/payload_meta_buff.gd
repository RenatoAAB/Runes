class_name PayloadMetaBuff
extends EffectPayload

@export var score_growth: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# This affects the SOURCE rune permanently (Meta Scaling)
	if source_rune.permanent_buffs.has("score_bonus"):
		source_rune.permanent_buffs["score_bonus"] += score_growth
	else:
		source_rune.permanent_buffs["score_bonus"] = score_growth

func get_description() -> String:
	return "Permanently gains +%d Score" % score_growth
