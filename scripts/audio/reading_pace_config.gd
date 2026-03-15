class_name ReadingPaceConfig
extends Resource

## Controls the speed/delay curve for the reader's step pacing.
## Extracted from Reader to be an independent Resource shared between
## Reader (step timing) and the sound system (note duration).

## Starting delay in seconds (used at 0 activations)
@export var speed_initial: float = 0.5
## Minimum delay cap — speed will never go below this
@export var speed_min: float = 0.05
## Curve type: "linear", "exponential", "logarithmic", "inverse", "step"
@export var speed_curve_type: String = "inverse"
## Generic curve parameter (meaning varies by curve type)
@export var speed_curve_param: float = 0.03
## Secondary curve parameter (used by some curves, e.g. step size for "step")
@export var speed_curve_param2: float = 5.0
## Whether dynamic speed is enabled (if false, always returns speed_initial)
@export var speed_dynamic_enabled: bool = true


## Calculates step delay for a given activation count.
## This is the single source of truth for pacing — used by Reader AND sound system.
## Curves available:
##   "linear"       : delay = initial - param * x
##   "exponential"  : delay = initial * exp(-param * x)
##   "logarithmic"  : delay = initial - param * ln(1 + x)
##   "inverse"      : delay = initial / (1 + param * x)
##   "step"         : delay drops by param every param2 activations
func get_delay(activation_count: int) -> float:
	if not speed_dynamic_enabled:
		return speed_initial

	var x := float(activation_count)
	var delay: float = speed_initial

	match speed_curve_type:
		"linear":
			delay = speed_initial - speed_curve_param * x
		"exponential":
			delay = speed_initial * exp(-speed_curve_param * x)
		"logarithmic":
			delay = speed_initial - speed_curve_param * log(1.0 + x)
		"inverse":
			delay = speed_initial / (1.0 + speed_curve_param * x)
		"step":
			var steps_down := floori(x / speed_curve_param2) if speed_curve_param2 > 0 else 0
			delay = speed_initial - speed_curve_param * steps_down
		_:
			delay = speed_initial

	return maxf(delay, speed_min)
