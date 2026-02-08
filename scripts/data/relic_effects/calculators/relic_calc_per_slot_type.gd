class_name RelicCalcPerSlotType
extends RelicMultiplierCalculator

## O Engenheiro
## ×1.1 por cada tipo de slot diferente no painel.

@export var per_type_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var types := stats.distinct_slot_types
	if types <= 0:
		return 1.0
	return pow(per_type_multiplier, types)


func get_description() -> String:
	return "×%.1f por cada tipo de slot diferente no painel." % per_type_multiplier
