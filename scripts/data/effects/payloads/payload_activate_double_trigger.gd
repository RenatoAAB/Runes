class_name PayloadActivateDoubleTrigger
extends EffectPayload

## Activates all target runes immediately (triggers them).
## Different from PayloadActivateRegion which queues them.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if not slot.is_empty():
			var target_rune = slot.rune
			if target_rune == source_rune:
				continue
			# Directly activate the rune
			if target_rune.can_activate():
				target_rune.on_activate(context, slot)
				print("Catalyst triggered %s" % target_rune.data.rune_name)

func get_description() -> String:
	return "Immediately triggers target runes"

func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER, Keywords.CHAIN]
