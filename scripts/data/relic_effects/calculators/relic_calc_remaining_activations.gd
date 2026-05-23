class_name RelicCalcRemainingActivations
extends RelicMultiplierCalculator

## O Escudeiro
## ×M^Y onde Y é o total de ativações restantes.

@export var per_activation_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var remaining := stats.remaining_activations_total
	if remaining <= 0:
		return 1.0
	return pow(per_activation_multiplier, remaining)


func get_description() -> String:
	return "×%.1f por cada ativação restante no painel." % per_activation_multiplier
