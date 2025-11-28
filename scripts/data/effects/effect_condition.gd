class_name EffectCondition
extends Resource

## Base class for conditions that determine if an effect can execute.

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return true
