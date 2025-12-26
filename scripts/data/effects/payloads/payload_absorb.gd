class_name PayloadAbsorb
extends EffectPayload

enum AbsorbType {
	SCORE_BONUS,
	ACTIVATION_BONUS
}

@export var absorb_type: AbsorbType = AbsorbType.SCORE_BONUS
@export var amount_per_target: int = 5

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var count = 0
	for slot in targets:
		if not slot.is_empty():
			count += 1
			# Optional: Destroy or weaken the absorbed rune?
			# For now, just "absorb power" implies gaining from them, not necessarily killing them.
			
	var total_gain = count * amount_per_target
	
	match absorb_type:
		AbsorbType.SCORE_BONUS:
			source_rune.stat_modifiers["score_bonus"] += total_gain
		AbsorbType.ACTIVATION_BONUS:
			source_rune.stat_modifiers["activation_bonus"] += total_gain

func get_description() -> String:
	var type_str = "Score" if absorb_type == AbsorbType.SCORE_BONUS else "Activations"
	return "Gains +%d %s per target" % [amount_per_target, type_str]

func get_keywords() -> Array[StringName]:
	return [Keywords.ABSORB, Keywords.BUFF]
