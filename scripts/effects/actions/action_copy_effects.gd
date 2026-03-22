class_name ActionCopyEffects
extends EffectAction

## Copies and executes ON_READ effects from a previously activated rune.
## Used by Empathy.

enum Source { PREVIOUS, NEXT }

@export var source: Source = Source.PREVIOUS


func execute(context: EffectContext, _targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(context, self, _targets)
	if not context or not context.battle or not context.source_rune:
		return

	var history = context.battle.activation_history
	if history.is_empty():
		return

	var source_entry: Dictionary
	match source:
		Source.PREVIOUS:
			if history.size() >= 2:
				source_entry = history[history.size() - 2]
			else:
				return
		Source.NEXT:
			return

	var source_rune_instance = source_entry.get("rune_instance")
	if not source_rune_instance or not source_rune_instance.data:
		return

	for effect in source_rune_instance.data.effects:
		if effect.trigger == GameEnums.EffectTrigger.ON_READ:
			if effect is GameEffect:
				effect.execute(context)


func get_description() -> String:
	match source:
		Source.PREVIOUS: return "repeat previous rune's effects"
		Source.NEXT: return "repeat next rune's effects"
	return ""


func get_keywords() -> Array[StringName]:
	return [&"copy", &"repeat"]
