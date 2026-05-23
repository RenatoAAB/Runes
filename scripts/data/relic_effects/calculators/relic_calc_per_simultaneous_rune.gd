class_name RelicCalcPerSimultaneousRune
extends RelicMultiplierCalculator

## O Condutor
## ×M por cada runa ativada simultaneamente na rodada.

@export var per_simultaneous_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.simultaneous_runes_activated_count
	if count <= 0:
		return 1.0
	return pow(per_simultaneous_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa ativada simultaneamente na rodada." % per_simultaneous_multiplier
