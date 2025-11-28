class_name RuneEffect
extends Resource

## Base class for all modular rune effects.
## In Task 3, we will expand this to include Condition, TargetArea, and Payload components.

# Placeholder for the execution logic.
# We use 'Object' for source_rune and grid_manager to avoid cyclic dependency issues 
# during the initial setup, but these will be typed as RuneInstance and GridManager later.
func execute(source_rune: Object, grid_manager: Object) -> void:
	pass
