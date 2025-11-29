class_name ConditionPreviousEffectSucceeded
extends EffectCondition

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return source_rune.last_effect_success

func get_description() -> String:
	return "the previous effect succeeded"
