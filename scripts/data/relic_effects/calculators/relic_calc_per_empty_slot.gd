class_name RelicCalcPerEmptySlot
extends RelicMultiplierCalculator

## O Nada
## ×1.05 por cada slot vazio no painel.

@export var per_empty_multiplier: float = 1.05


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.empty_slots_count
	if count <= 0:
		return 1.0
	return pow(per_empty_multiplier, count)


func get_description() -> String:
	return "×%.2f por cada slot vazio no painel." % per_empty_multiplier
