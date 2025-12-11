class_name PayloadRhythmChainBuff
extends EffectPayload

## Buffs all Rhythm runes with additional bonus based on previous rhythm activations.

@export var base_score_bonus: int = 5

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	# Get count of previous rhythm activations
	var rhythm_count = context.get_meta("rhythm_activation_count", 0)
	var total_bonus = base_score_bonus * rhythm_count
	
	if total_bonus > 0:
		# Find all rhythm runes and buff them
		for slot in context.grid.grid:
			if not slot.is_empty():
				if slot.rune.data.element == GameEnums.Element.RHYTHM:
					slot.rune.permanent_buffs["score_bonus"] = slot.rune.permanent_buffs.get("score_bonus", 0) + total_bonus
					print("Rhythm Chain: Buffed %s by +%d" % [slot.rune.data.rune_name, total_bonus])

func get_description() -> String:
	return "All Rhythm runes gain +%d × previous Rhythm activations" % base_score_bonus
