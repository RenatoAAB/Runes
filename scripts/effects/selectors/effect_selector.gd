class_name EffectSelector
extends Resource

## Base class for selecting which slots are affected by an effect.
## Replaces the old EffectTarget with clearer naming and SlotFilter support.

func select(ctx: EffectContext) -> Array[GridSlot]:
	return []


func get_preview(ctx: EffectContext) -> Array[GridSlot]:
	return select(ctx)


func get_description() -> String:
	return ""


func get_description_colored(effect_index: int) -> String:
	var desc = get_description()
	if desc.is_empty():
		return ""
	return EffectColors.colorize_text(desc, effect_index)


func get_keywords() -> Array[StringName]:
	return []
