class_name EffectPayload
extends Resource

## Base class for the actual action performed by the effect.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	pass

## Returns a plain text description of this payload.
func get_description() -> String:
	return ""

## Returns a BBCode-formatted description.
## The target_desc should already be colored if needed.
func get_description_with_target(target_desc: String) -> String:
	var desc = get_description()
	if target_desc.is_empty():
		return desc
	
	# Replace "targets" or "target" with the actual target description
	if "targets" in desc:
		return desc.replace("targets", target_desc)
	elif "target" in desc:
		return desc.replace("target", target_desc)
	else:
		# Append target info if no placeholder
		return desc + " on " + target_desc

## Returns the keywords associated with this payload.
## Override in subclasses to return specific keywords.
func get_keywords() -> Array[StringName]:
	return []
