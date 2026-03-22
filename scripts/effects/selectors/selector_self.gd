class_name SelectorSelf
extends EffectSelector

## Selects only the source slot.

func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not ctx.source_slot:
		return []
	var result: Array[GridSlot] = [ctx.source_slot]
	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	return "Self"


func get_keywords() -> Array[StringName]:
	return [Keywords.SELF]
