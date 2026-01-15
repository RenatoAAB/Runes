class_name PayloadAddPermanentScore
extends EffectPayload

## Adds a flat permanent score bonus to the source rune.
## Use when you want a fixed permanent buff independent of elements/targets.

@export var amount: int = 0

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, _context: BattleContext) -> void:
	if amount == 0:
		return
	apply_score(amount, source_rune, _context, true)


func get_description() -> String:
	return "Gain +%d permanent score" % amount


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE]
