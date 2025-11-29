class_name PayloadBuffActivation
extends EffectPayload

@export var activation_bonus: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			# Update the stat_modifiers directly as this is where get_max_activations looks
			if target_rune.stat_modifiers.has("activation_bonus"):
				target_rune.stat_modifiers["activation_bonus"] += activation_bonus
			else:
				target_rune.stat_modifiers["activation_bonus"] = activation_bonus
			
			print("Buffed Rune %s with +%d activations" % [target_rune.data.rune_name, activation_bonus])

func get_description() -> String:
	return "Adds +%d Max Activations" % activation_bonus
