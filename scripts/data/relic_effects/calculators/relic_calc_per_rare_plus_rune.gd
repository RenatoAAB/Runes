class_name RelicCalcPerRarePlusRune
extends RelicMultiplierCalculator

## O Colecionador
## ×M por cada runa de raridade Rara ou superior presente no painel.

@export var per_rare_plus_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.rare_plus_runes_in_panel
	if count <= 0:
		return 1.0
	return pow(per_rare_plus_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada runa de raridade Rara ou superior presente no painel." % per_rare_plus_multiplier
