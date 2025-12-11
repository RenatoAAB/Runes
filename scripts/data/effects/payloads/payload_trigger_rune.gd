class_name PayloadTriggerRune
extends EffectPayload

## Forces target runes to activate immediately, consuming one of their activations.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			if target_rune.can_activate():
				# Queue this rune for immediate activation
				context.queue_rune_activation(slot)
				print("Triggered activation of %s" % target_rune.data.rune_name)

func get_description() -> String:
	return "Triggers target runes to activate"
