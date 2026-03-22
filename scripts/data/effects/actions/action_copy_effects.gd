class_name ActionCopyEffects
extends EffectAction

enum Source { PREVIOUS, NEXT }

@export var source: Source = Source.PREVIOUS

func execute(context: EffectContext, targets: Array[GridSlot]) -> void:
	if not context.battle or not context.source_rune:
		return
	var history = context.battle.activation_history
	if history.is_empty():
		return
	var source_entry: Dictionary
	match source:
		Source.PREVIOUS:
			if history.size() >= 2:  # At least self + one previous
				source_entry = history[history.size() - 2]
			else:
				return
		Source.NEXT:
			return  # Next is harder to implement, skip for now
	var source_rune_instance = source_entry.get("rune_instance")
	if not source_rune_instance or not source_rune_instance.data:
		return
	# Execute all ON_READ effects of the copied rune
	for effect in source_rune_instance.data.effects:
		if effect.trigger == GameEnums.EffectTrigger.ON_READ:
			if effect is GameEffect:
				effect.execute(context)
			elif effect is RuneEffect:
				effect.execute(context.source_rune, context.battle, context.source_slot)

func get_description() -> String:
	match source:
		Source.PREVIOUS: return "repeat previous rune's effects"
		Source.NEXT: return "repeat next rune's effects"
	return ""

func get_keywords() -> Array[StringName]:
	return [&"copy", &"repeat"]
