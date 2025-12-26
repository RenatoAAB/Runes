class_name PayloadModifyRune
extends EffectPayload

enum ModificationType {
	BUFF_SCORE_FLAT,
	BUFF_SCORE_MULT,
	BUFF_ACTIVATION,
	DISABLE,
	ENABLE
}

@export var modification: ModificationType = ModificationType.BUFF_SCORE_FLAT
@export var value: float = 0.0 # Use 1.0 for +1 flat or +100% mult

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var rune = slot.rune
			match modification:
				ModificationType.BUFF_SCORE_FLAT:
					rune.stat_modifiers["score_bonus"] += int(value)
				ModificationType.BUFF_SCORE_MULT:
					rune.stat_modifiers["score_multiplier"] += value
				ModificationType.BUFF_ACTIVATION:
					rune.stat_modifiers["activation_bonus"] += int(value)
				ModificationType.DISABLE:
					rune.is_disabled = true
				ModificationType.ENABLE:
					rune.is_disabled = false

func get_description() -> String:
	match modification:
		ModificationType.BUFF_SCORE_FLAT: return "Buffs Rune Score by +%d" % int(value)
		ModificationType.BUFF_SCORE_MULT: return "Multiplies Rune Score by +%.1f" % value
		ModificationType.BUFF_ACTIVATION: return "Adds %d Activations" % int(value)
		ModificationType.DISABLE: return "Disables Rune"
		ModificationType.ENABLE: return "Enables Rune"
	return ""

func get_keywords() -> Array[StringName]:
	match modification:
		ModificationType.BUFF_SCORE_FLAT, ModificationType.BUFF_SCORE_MULT, ModificationType.BUFF_ACTIVATION:
			return [Keywords.BUFF]
		ModificationType.DISABLE:
			return [Keywords.DISABLED, Keywords.DEBUFF]
		ModificationType.ENABLE:
			return [Keywords.BUFF]
	return []
