class_name RelicCalcPerCreated
extends RelicMultiplierCalculator

## O Criador
## ×1.2 por cada runa criada nesta rodada.

@export var per_created_multiplier: float = 1.2


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.runes_created_count
	if count <= 0:
		return 1.0
	return pow(per_created_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa criada nesta rodada." % per_created_multiplier
