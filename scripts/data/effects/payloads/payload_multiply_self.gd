class_name PayloadMultiplySelf
extends EffectPayload

## Multiplies the source rune's score value (not global score).
## This is different from PayloadMultiplyGlobalScore which multiplies the entire accumulated score.

@export var multiplier: float = 1.5

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Add to the source rune's score multiplier
	source_rune.stat_modifiers["score_multiplier"] += (multiplier - 1.0)
	print("Multiplied self score by %.2f (Rune: %s)" % [multiplier, source_rune.data.rune_name])

func get_description() -> String:
	return "Multiplies own Score by x%.1f" % multiplier
