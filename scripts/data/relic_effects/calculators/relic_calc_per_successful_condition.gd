class_name RelicCalcPerSuccessfulCondition
extends RelicMultiplierCalculator

## O Alquimista
## ×M por cada condição bem-sucedida no painel.

@export var per_condition_multiplier: float = 1.05


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.successful_conditions_count
	if count <= 0:
		return 1.0
	return pow(per_condition_multiplier, count)


func get_description() -> String:
	return "×%.2f por cada condição bem-sucedida no painel." % per_condition_multiplier
