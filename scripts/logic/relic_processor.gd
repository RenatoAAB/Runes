class_name RelicProcessor
extends RefCounted

## Orchestrates the execution of all relics attached to a panel after the Reader finishes.
##
## Flow:
##   1. Reader finishes → BattleRoundStatistics is built
##   2. RelicProcessor.process_relics() is called with the panel's relics
##   3. Each relic's calculator produces a multiplier
##   4. All multipliers are accumulated (product)
##   5. Returns the final combined multiplier
##
## A combined multiplier of 1.0 means relics had no effect.

signal relic_processed(relic: RelicInstance, multiplier: float, index: int)
signal all_relics_processed(combined_multiplier: float)


## Process all relics for a panel and return the combined multiplier.
## Relics are processed in order (left-to-right as attached).
## Only relics with the new calculator system are processed; legacy relics are skipped.
func process_relics(relics: Array, stats: BattleRoundStatistics) -> float:
	var combined: float = 1.0

	for i in range(relics.size()):
		var relic = relics[i] as RelicInstance
		if relic == null or not relic.is_active:
			continue

		if not relic.has_calculator():
			# Legacy relic — skip new processing (legacy system still handles these)
			continue

		var mult := relic.calculate_multiplier(stats)
		combined *= mult
		relic_processed.emit(relic, mult, i)

	all_relics_processed.emit(combined)
	return combined


## Convenience: build stats and process in one call.
## Returns a Dictionary with { combined_multiplier: float, stats: BattleRoundStatistics }
func build_and_process(relics: Array, context: BattleContext, grid: GridManager) -> Dictionary:
	var stats := BattleRoundStatistics.build_from(context, grid)
	var combined := process_relics(relics, stats)
	return {
		"combined_multiplier": combined,
		"stats": stats,
	}
