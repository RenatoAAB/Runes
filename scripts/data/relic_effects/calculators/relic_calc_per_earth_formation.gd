class_name RelicCalcPerEarthFormation
extends RelicMultiplierCalculator

## A Crianca
## ×M por cada formacao rochosa no painel.

@export var per_formation_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.earth_formations_count
	if count <= 0:
		return 1.0
	return pow(per_formation_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada formacao rochosa no painel." % per_formation_multiplier
