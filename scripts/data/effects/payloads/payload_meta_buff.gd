class_name PayloadMetaBuff
extends EffectPayload

@export var score_growth: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Apply permanent buff to all valid targets
	for slot in targets:
		if not slot.is_empty():
			var rune = slot.rune
			if rune.permanent_buffs.has("score_bonus"):
				rune.permanent_buffs["score_bonus"] += score_growth
			else:
				rune.permanent_buffs["score_bonus"] = score_growth

func get_description() -> String:
	return "Permanently grants +%d Score to targets" % score_growth
