class_name EffectLogger
extends RefCounted

## Structured debug logging for the effect system.
## Enable during development, disable in production.

static var enabled: bool = true
static var verbosity: int = 2
static var filter_rune_id: StringName = &""

const TAG = "[Effect]"


static func log_trigger(ctx: EffectContext, effect: Resource) -> void:
	if not _should_log(ctx, 1):
		return
	var trigger_name = ""
	if effect and "trigger" in effect:
		trigger_name = GameEnums.EffectTrigger.keys()[effect.trigger]
	print("%s TRIGGER %s | rune=%s | slot=%s" % [TAG,
		trigger_name,
		ctx.source_rune.data.id if ctx and ctx.source_rune and ctx.source_rune.data else "null",
		str(ctx.source_slot.grid_position) if ctx and ctx.source_slot else "null"])


static func log_condition(ctx: EffectContext, condition: Resource, result: bool) -> void:
	if not _should_log(ctx, 2):
		return
	var cond_name = condition.resource_name if condition else "Always"
	if cond_name.is_empty() and condition:
		cond_name = condition.get_script().get_global_name() if condition.get_script() else "Unknown"
	print("%s   CONDITION %s → %s" % [TAG,
		cond_name,
		"PASS" if result else "FAIL"])


static func log_selector(ctx: EffectContext, selector: Resource, targets: Array) -> void:
	if not _should_log(ctx, 2):
		return
	var sel_name = selector.resource_name if selector else "None"
	if sel_name.is_empty() and selector:
		sel_name = selector.get_script().get_global_name() if selector.get_script() else "Unknown"
	var coords = targets.map(func(s): return str(s.grid_position) if s else "null")
	print("%s   SELECTOR %s → %d targets %s" % [TAG,
		sel_name,
		targets.size(), str(coords)])


static func log_action(ctx: EffectContext, action: Resource, targets: Array) -> void:
	if not _should_log(ctx, 2):
		return
	var act_name = action.resource_name if action else "None"
	if act_name.is_empty() and action:
		act_name = action.get_script().get_global_name() if action.get_script() else "Unknown"
	print("%s   ACTION %s → targets=%d" % [TAG,
		act_name,
		targets.size()])


static func log_value_resolved(ctx: EffectContext, resolver: ValueResolver, base_val: float, result: float) -> void:
	if not _should_log(ctx, 3):
		return
	print("%s     VALUE base=%.1f → resolved=%.1f (per_count=%d, multiplier=%.2f)" % [TAG,
		base_val, result,
		resolver.per.size() if resolver else 0,
		resolver.final_multiplier if resolver else 1.0])


static func log_score(ctx: EffectContext, amount: int, source_desc: String) -> void:
	if not _should_log(ctx, 1):
		return
	print("%s   SCORE %+d from %s | total=%d" % [TAG, amount, source_desc,
		ctx.battle.current_score if ctx and ctx.battle else 0])


static func log_effect_complete(ctx: EffectContext, effect: Resource, success: bool) -> void:
	if not _should_log(ctx, 1):
		return
	var effect_name = effect.resource_name if effect else "?"
	if effect_name.is_empty() and effect:
		effect_name = effect.get_script().get_global_name() if effect and effect.get_script() else "?"
	print("%s COMPLETE %s → %s" % [TAG,
		effect_name,
		"SUCCESS" if success else "SKIPPED"])


static func log_integration(system: String, message: String) -> void:
	if not enabled:
		return
	print("[Integration] %s: %s" % [system, message])


static func _should_log(ctx: EffectContext, min_verbosity: int) -> bool:
	if not enabled or verbosity < min_verbosity:
		return false
	if filter_rune_id != &"" and ctx and ctx.source_rune and ctx.source_rune.data:
		return ctx.source_rune.data.id == filter_rune_id
	return true
