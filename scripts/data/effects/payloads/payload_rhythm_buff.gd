class_name PayloadRhythmBuff
extends EffectPayload

## Buffs all Rhythm runes permanently when activation multiple condition is met.

@export var score_bonus: int = 5

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Mark that a rhythm rune activated its condition
	context.set_meta("rhythm_activated", true)
	
	# Get count of previous rhythm activations
	var rhythm_count = context.get_meta("rhythm_activation_count", 0)
	context.set_meta("rhythm_activation_count", rhythm_count + 1)
	
	# Find all rhythm runes and buff them
	for slot in context.grid.grid:
		if not slot.is_empty():
			if slot.rune.data.element == GameEnums.Element.RHYTHM:
				slot.rune.permanent_buffs["score_bonus"] = slot.rune.permanent_buffs.get("score_bonus", 0) + score_bonus
				print("Rhythm: Buffed %s by +%d" % [slot.rune.data.rune_name, score_bonus])

func get_description() -> String:
	return "All Rhythm runes gain +%d permanent Score" % score_bonus
