class_name PayloadTriggerTargets
extends EffectPayload

## Activates all target runes immediately (consumes their activation if available).
func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		if target_rune == source_rune:
			continue
		if target_rune.can_activate():
			target_rune.on_activate(context, slot)
			print("%s triggered %s" % [source_rune.data.rune_name, target_rune.data.rune_name])

func get_description() -> String:
	return "Immediately triggers target runes"

func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER, Keywords.CHAIN]
