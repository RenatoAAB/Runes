class_name ActionComposite
extends EffectAction

## Executes a list of sub-actions sequentially on the same targets.

@export var actions: Array[EffectAction] = []


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	for action in actions:
		if action:
			action.execute(ctx, targets)


func get_description() -> String:
	var descs: Array[String] = []
	for sub_action in actions:
		if sub_action:
			var d = sub_action.get_description()
			if not d.is_empty():
				descs.append(d)
	return ". ".join(descs)


func get_description_with_context(ctx: EffectContext) -> String:
	var descs: Array[String] = []
	for sub_action in actions:
		if sub_action:
			var d = sub_action.get_description_with_context(ctx)
			if not d.is_empty():
				descs.append(d)
	if descs.is_empty():
		return get_description()
	return ". ".join(descs)


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	var result: Array[GridSlot] = []
	for action in actions:
		if action:
			for slot in action.get_value_source_slots(ctx):
				if slot not in result:
					result.append(slot)
	return result


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = []
	for action in actions:
		if action:
			for k in action.get_keywords():
				if k not in kw:
					kw.append(k)
	return kw
