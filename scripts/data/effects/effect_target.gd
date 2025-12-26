class_name EffectTarget
extends Resource

## Base class for determining which slots are affected by an effect.

func get_targets(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> Array[GridSlot]:
	return []

## Returns a plain text description of this target.
func get_description() -> String:
	return ""

## Returns a BBCode-formatted description with the effect color applied.
func get_description_colored(effect_index: int) -> String:
	var desc = get_description()
	if desc.is_empty():
		return ""
	return EffectColors.colorize_text(desc, effect_index)

## Returns the keywords associated with this target.
## Override in subclasses to return specific keywords.
func get_keywords() -> Array[StringName]:
	return []
