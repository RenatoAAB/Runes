class_name PayloadMultiplyScorePermanent
extends EffectPayload

@export var multiplier: float = 2.0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var current_multiplier = source_rune.permanent_buffs.get("score_multiplier", 1.0)
	var mult = _get_enhancer_multiplier(context.current_slot if context else null)
	source_rune.permanent_buffs["score_multiplier"] = current_multiplier * (multiplier * mult)

func get_description() -> String:
	return "Permanently multiply score by %s" % multiplier

func get_keywords() -> Array[StringName]:
	return [Keywords.SCALING, Keywords.MULTIPLY]
