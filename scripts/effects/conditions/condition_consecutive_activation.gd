class_name ConditionConsecutiveActivation
extends NewEffectCondition

## Checks if the source rune was activated consecutively (the previous activation
## in reader history was the same rune instance).
## Used by Plasma: "ativada 2x consecutivas sem uma runa no meio".

@export var required_consecutive_count: int = 2


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle or not ctx.source_rune:
		return false

	var history = ctx.battle.activation_history
	if history.size() < required_consecutive_count:
		return false

	# Check the last N entries in history are all the same rune instance
	var start_idx = history.size() - required_consecutive_count
	for i in range(start_idx, history.size()):
		var entry = history[i]
		if entry.get("rune_instance") != ctx.source_rune:
			return false
	return true


func get_description() -> String:
	if required_consecutive_count == 2:
		return "activated consecutively"
	return "activated %dx consecutively" % required_consecutive_count


func get_keywords() -> Array[StringName]:
	return [Keywords.SEQUENCE]
