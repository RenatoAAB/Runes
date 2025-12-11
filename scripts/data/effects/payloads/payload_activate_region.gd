class_name PayloadActivateRegion
extends EffectPayload

## Activates all runes in a region (like a catalyst).

@export var activation_bonus: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			# Don't activate self again
			if target_rune == source_rune:
				continue
			# Add activation bonus to the rune
			if not target_rune.stat_modifiers.has("activation_bonus"):
				target_rune.stat_modifiers["activation_bonus"] = activation_bonus
			else:
				target_rune.stat_modifiers["activation_bonus"] += activation_bonus
			# Queue for activation
			context.queue_rune_activation(slot)
			print("Catalyst activated %s" % target_rune.data.rune_name)

func get_description() -> String:
	return "Activates all targets (+%d activation)" % activation_bonus
