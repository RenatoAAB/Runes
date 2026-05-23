class_name RelicCalcLargestFormationThreshold
extends RelicMultiplierCalculator

## O Baluarte
## ×X se a maior formacao rochosa tiver mais de N runas.

@export var threshold_size: int = 12
@export var threshold_multiplier: float = 2.0


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	return threshold_multiplier if stats.largest_earth_formation_size > threshold_size else 1.0


func get_description() -> String:
	return "×%.1f se a maior formacao rochosa tiver mais de %d runas." % [threshold_multiplier, threshold_size]
