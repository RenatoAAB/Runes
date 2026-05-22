class_name SelectorPreviousTriggerTargets
extends EffectSelector

## Selects slots that were actually activated by the immediately previous
## ActionTriggerActivation execution in this battle context.


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.battle:
		return []

	var stored = ctx.battle.get_meta("last_trigger_activation_targets", [])
	var result: Array[GridSlot] = []

	if stored is Array:
		for entry in stored:
			if entry is GridSlot and not entry.is_void() and entry not in result:
				result.append(entry)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	return "Runes activated by previous effect"


func get_keywords() -> Array[StringName]:
	return [Keywords.CHAIN, Keywords.TRIGGER]
