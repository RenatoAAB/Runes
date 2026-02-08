class_name RelicCalcPerUniqueRune
extends RelicMultiplierCalculator

## O Alquimista
## ×1.1 por cada runa única ativada nesta rodada.

@export var per_unique_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.unique_runes_count
	if count <= 0:
		return 1.0
	return pow(per_unique_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa única ativada nesta rodada." % per_unique_multiplier
