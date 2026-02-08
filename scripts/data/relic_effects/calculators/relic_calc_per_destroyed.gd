class_name RelicCalcPerDestroyed
extends RelicMultiplierCalculator

## O Destruidor
## ×1.2 por cada runa destruída nesta rodada.

@export var per_destroyed_multiplier: float = 1.2


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.runes_destroyed_count
	if count <= 0:
		return 1.0
	return pow(per_destroyed_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa destruída nesta rodada." % per_destroyed_multiplier
