class_name RelicCalcElementBalance
extends RelicMultiplierCalculator

## O Equilibrista
## ×3 se a contagem de ativações por elemento presente for igual.

@export var balanced_multiplier: float = 3.0


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	return balanced_multiplier if stats.is_element_balanced() else 1.0


func get_description() -> String:
	return "×%.1f se a contagem de ativações por elemento presente for igual." % balanced_multiplier
