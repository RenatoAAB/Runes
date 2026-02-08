class_name RelicCalcPerUnmovedRune
extends RelicMultiplierCalculator

## O Baluarte
## ×1.1 por cada runa não movida nesta rodada.

@export var per_unmoved_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.runes_not_moved_count
	if count <= 0:
		return 1.0
	return pow(per_unmoved_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa não movida nesta rodada." % per_unmoved_multiplier
