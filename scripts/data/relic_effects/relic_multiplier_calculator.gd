class_name RelicMultiplierCalculator
extends Resource

## Base class for all relic multiplier calculators.
## Each relic type extends this class and implements its own logic
## to compute a score multiplier based on BattleRoundStatistics.
##
## Pattern: input = BattleRoundStatistics → output = float (multiplier)
##
## The multiplier is applied post-panel: final_score = raw_score × Π(multipliers).
## A multiplier of 1.0 means "no effect".


## Compute the multiplier this relic contributes.
## Override in subclasses.
## Returns a float ≥ 0.  A value of 1.0 means neutral.
func calculate_multiplier(_stats: BattleRoundStatistics) -> float:
	return 1.0


## Human-readable description of what this calculator does.
## Used in tooltips.  Override in subclasses.
func get_description() -> String:
	return ""


## Optional: return a preview of what the multiplier *would be*
## given a hypothetical stats snapshot (useful for UI previews).
func preview_multiplier(stats: BattleRoundStatistics) -> String:
	var mult := calculate_multiplier(stats)
	if mult == 1.0:
		return "×1.0 (no effect)"
	return "×%.2f" % mult
