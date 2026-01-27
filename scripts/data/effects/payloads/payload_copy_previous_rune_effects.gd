class_name PayloadCopyPreviousRuneEffects
extends EffectPayload

## Copies ON_READ effects of the previous rune in sequence, executing them as if this rune cast them.
## Consumes this rune's activation (handled by the caller); does not trigger the previous rune's activation.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context:
		return
	var source_slot := context.current_slot
	if not source_slot:
		return
	for slot in targets:
		if slot.is_empty():
			continue
		var ref_rune := slot.rune
		for effect in ref_rune.data.effects:
			if effect.trigger != GameEnums.EffectTrigger.ON_READ:
				continue
			effect.execute(source_rune, context, source_slot)


func get_description() -> String:
	return "Copy effects of rune"


func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER, Keywords.CHAIN]
