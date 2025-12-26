class_name PayloadCrystalCorner
extends EffectPayload

## Adds permanent score bonus if in corner position.

@export var score_bonus: int = 5

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	source_rune.permanent_buffs["score_bonus"] = source_rune.permanent_buffs.get("score_bonus", 0) + score_bonus
	print("Crystal: Gained +%d permanent score from corner" % score_bonus)

func get_description() -> String:
	return "Gains +%d permanent Score" % score_bonus

func get_keywords() -> Array[StringName]:
	return [Keywords.SCALING, Keywords.POSITION]
