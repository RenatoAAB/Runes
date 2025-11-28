class_name PayloadAddScore
extends EffectPayload

@export var score_amount: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, grid_manager: GridManager) -> void:
	# In a real implementation, we would emit a signal or call a method on a ScoreManager.
	# For now, we'll print to console to verify logic.
	print("Adding Score: %d from Rune %s" % [score_amount, source_rune.data.rune_name])
	# We might also want to visualize this on the target slots later.
