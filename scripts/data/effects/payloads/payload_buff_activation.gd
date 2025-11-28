class_name PayloadBuffActivation
extends EffectPayload

@export var activation_bonus: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, grid_manager: GridManager) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			# We need to implement a way to add buffs to RuneInstance.
			# For now, we will directly modify a temporary buff dictionary.
			if target_rune.temporary_buffs.has("max_activations_bonus"):
				target_rune.temporary_buffs["max_activations_bonus"] += activation_bonus
			else:
				target_rune.temporary_buffs["max_activations_bonus"] = activation_bonus
			
			print("Buffed Rune %s with +%d activations" % [target_rune.data.rune_name, activation_bonus])
