class_name RelicCalcPerElementCycle
extends RelicMultiplierCalculator

## O Dançarino
## ×1.1 por cada ciclo completo de 5 elementos distintos consecutivos.

@export var per_cycle_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var cycles := stats.element_cycles_completed
	if cycles <= 0:
		return 1.0
	return pow(per_cycle_multiplier, cycles)


func get_description() -> String:
	return "×%.1f por cada ciclo completo de 5 elementos distintos." % per_cycle_multiplier
