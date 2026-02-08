class_name RelicCalcPerLoop
extends RelicMultiplierCalculator

## O Retorno
## ×2 por cada loop infinito criado.

@export var per_loop_multiplier: float = 2.0


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var loops := stats.infinite_loops_count
	if loops <= 0:
		return 1.0
	return pow(per_loop_multiplier, loops)


func get_description() -> String:
	return "×%.1f por cada loop infinito criado." % per_loop_multiplier
