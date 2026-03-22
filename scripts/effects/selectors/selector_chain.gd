class_name SelectorChain
extends EffectSelector

## Chains two selectors: gets results from selector_a, then for each result
## applies selector_b using that slot as source.

@export var selector_a: EffectSelector
@export var selector_b: EffectSelector
@export var filter: SlotFilter


func select(ctx: EffectContext) -> Array[GridSlot]:
	if not ctx or not selector_a or not selector_b:
		return []

	var intermediate = selector_a.select(ctx)
	var result: Array[GridSlot] = []

	for slot in intermediate:
		var sub_ctx = EffectContext.new(ctx.source_rune, slot, ctx.battle)
		sub_ctx.effect_index = ctx.effect_index
		sub_ctx.can_evaluate = ctx.can_evaluate
		var sub_targets = selector_b.select(sub_ctx)
		for target in sub_targets:
			if filter and not filter.matches(target, ctx.battle):
				continue
			if target not in result:
				result.append(target)

	EffectLogger.log_selector(ctx, self, result)
	return result


func get_description() -> String:
	var a_desc = selector_a.get_description() if selector_a else "?"
	var b_desc = selector_b.get_description() if selector_b else "?"
	return "%s → %s" % [a_desc, b_desc]


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = []
	if selector_a:
		for k in selector_a.get_keywords():
			if k not in kw:
				kw.append(k)
	if selector_b:
		for k in selector_b.get_keywords():
			if k not in kw:
				kw.append(k)
	return kw
