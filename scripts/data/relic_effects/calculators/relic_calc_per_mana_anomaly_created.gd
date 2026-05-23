class_name RelicCalcPerManaAnomalyCreated
extends RelicMultiplierCalculator

## O Anomalo
## ×M por cada anomalia de mana criada na rodada.

@export var per_anomaly_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.mana_anomalies_created_count
	if count <= 0:
		return 1.0
	return pow(per_anomaly_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada anomalia de mana criada nessa rodada." % per_anomaly_multiplier
