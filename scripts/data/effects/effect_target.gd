class_name EffectTarget
extends Resource

## Base class for determining which slots are affected by an effect.

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return []
