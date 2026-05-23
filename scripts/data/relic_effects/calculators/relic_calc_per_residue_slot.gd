class_name RelicCalcPerResidueSlot
extends RelicMultiplierCalculator

## O Palhaço
## ×1.1 por cada slot com resíduo rúnico ao final do round.

@export var per_residue_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.slots_with_residue
	if count <= 0:
		return 1.0
	return pow(per_residue_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada slot com resíduo rúnico ao final do round." % per_residue_multiplier
