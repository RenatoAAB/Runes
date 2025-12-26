class_name PayloadMultiplyTargetScore
extends EffectPayload

## Multiplies the score multiplier of target runes.

@export var multiplier: float = 1.1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			if target_rune == source_rune:
				continue
			# Add to their permanent score multiplier
			if not target_rune.permanent_buffs.has("score_multiplier"):
				target_rune.permanent_buffs["score_multiplier"] = multiplier
			else:
				target_rune.permanent_buffs["score_multiplier"] *= multiplier
			print("Lava: Multiplied %s score by %.1f" % [target_rune.data.rune_name, multiplier])

func get_description() -> String:
	return "Multiplies target runes' score by %.1f" % multiplier

func get_keywords() -> Array[StringName]:
	return [Keywords.MULTIPLY, Keywords.BUFF]
