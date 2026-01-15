class_name PayloadAddPermanentScore
extends EffectPayload

## Adds a flat permanent score bonus to the source rune.
## Use when you want a fixed permanent buff independent of elements/targets.

@export var amount: int = 0

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, _context: BattleContext) -> void:
	if amount == 0:
		return
	var current = source_rune.permanent_buffs.get("score_bonus", 0)
	source_rune.permanent_buffs["score_bonus"] = current + amount
	print("%s: +%d permanent score" % [source_rune.data.rune_name, amount])


func get_description() -> String:
	return "Gain +%d permanent score" % amount


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE]
