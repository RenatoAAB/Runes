class_name ConditionRhythmChain
extends EffectCondition

## Returns true if another Rhythm rune had its condition activated this sequence.

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	return context.get_meta("rhythm_activated", false)

func get_description() -> String:
	return "another Rhythm activated"
