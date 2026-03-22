class_name ConditionComposite
extends NewEffectCondition

## Combines multiple sub-conditions with AND/OR logic.

enum Mode {
	AND,
	OR
}

@export var mode: Mode = Mode.AND
@export var conditions: Array[NewEffectCondition] = []


func evaluate(ctx: EffectContext) -> bool:
	if conditions.is_empty():
		return true

	EffectLogger.log_condition(ctx, self, false)  # Will be overwritten below

	match mode:
		Mode.AND:
			for cond in conditions:
				if cond and not cond.evaluate(ctx):
					EffectLogger.log_condition(ctx, self, false)
					return false
			EffectLogger.log_condition(ctx, self, true)
			return true
		Mode.OR:
			for cond in conditions:
				if cond and cond.evaluate(ctx):
					EffectLogger.log_condition(ctx, self, true)
					return true
			EffectLogger.log_condition(ctx, self, false)
			return false

	return true


func get_highlight_slots(ctx: EffectContext) -> Array[GridSlot]:
	var result: Array[GridSlot] = []
	for cond in conditions:
		if cond:
			for slot in cond.get_highlight_slots(ctx):
				if slot not in result:
					result.append(slot)
	return result


func get_description() -> String:
	var descs: Array[String] = []
	for cond in conditions:
		if cond:
			var d = cond.get_description()
			if not d.is_empty() and d != "Always":
				descs.append(d)
	if descs.is_empty():
		return ""
	var connector = " AND " if mode == Mode.AND else " OR "
	return connector.join(descs)


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = []
	for cond in conditions:
		if cond:
			for k in cond.get_keywords():
				if k not in kw:
					kw.append(k)
	return kw
