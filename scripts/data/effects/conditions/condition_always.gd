class_name ConditionAlways
extends EffectCondition

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return true
