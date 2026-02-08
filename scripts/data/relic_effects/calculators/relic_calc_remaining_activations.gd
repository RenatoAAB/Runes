class_name RelicCalcRemainingActivations
extends RelicMultiplierCalculator

## O Escudeiro
## ×(1 + Y×0.01) onde Y é o total de ativações restantes.

@export var percent_per_activation: float = 0.01


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var remaining := stats.remaining_activations_total
	if remaining <= 0:
		return 1.0
	return 1.0 + (remaining * percent_per_activation)


func get_description() -> String:
	return "×(1 + Y×%.2f) onde Y é o total de ativações restantes." % percent_per_activation
