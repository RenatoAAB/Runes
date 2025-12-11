class_name PayloadCopyEffect
extends EffectPayload

## Copies/duplicates the effect of adjacent runes (Light mechanic).
## Actually applies a multiplier to all runes in targets.

@export var effect_multiplier: float = 2.0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			# Mark this rune to have its effects doubled this turn
			if not target_rune.stat_modifiers.has("effect_multiplier"):
				target_rune.stat_modifiers["effect_multiplier"] = effect_multiplier
			else:
				target_rune.stat_modifiers["effect_multiplier"] *= effect_multiplier
			print("Doubled effects of %s" % target_rune.data.rune_name)

func get_description() -> String:
	return "Doubles the effects of targets"
