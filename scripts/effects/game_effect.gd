class_name GameEffect
extends Resource

## Unified effect container: trigger + condition + selector + action.
## Used by runes, slot modifiers, relics, and residues.

@export var trigger: GameEnums.EffectTrigger = GameEnums.EffectTrigger.ON_READ
@export var condition: NewEffectCondition
@export var selector: EffectSelector
@export var action: EffectAction
@export_multiline var description_override: String = ""


func execute(ctx: EffectContext) -> bool:
	EffectLogger.log_trigger(ctx, self)

	if not selector or not action:
		push_warning("GameEffect missing selector or action.")
		if ctx.source_rune:
			ctx.source_rune.last_effect_success = false
		EffectLogger.log_effect_complete(ctx, self, false)
		return false

	# Evaluate condition (null condition = always true)
	var condition_met: bool = true
	if condition:
		condition_met = bool(condition.evaluate(ctx))
	var raw_condition_met: bool = condition_met
	EffectLogger.log_condition(ctx, condition, condition_met)

	# Slot Refractor bypass
	if not condition_met and ctx.source_slot:
		if ctx.source_slot.slot and ctx.source_slot.slot.data and ctx.source_slot.slot.data.id == "slot_refractor":
			condition_met = true

	if not condition_met:
		if ctx.source_rune:
			ctx.source_rune.last_effect_success = false
		EffectLogger.log_effect_complete(ctx, self, false)
		return false

	if condition and raw_condition_met and ctx.battle:
		ctx.battle.record_successful_condition()

	# Select targets
	var targets = selector.select(ctx)

	if targets.is_empty():
		if ctx.source_rune:
			ctx.source_rune.last_effect_success = false
		EffectLogger.log_effect_complete(ctx, self, false)
		return false

	# Execute action
	action.execute(ctx, targets)

	if ctx.source_rune:
		ctx.source_rune.last_effect_success = true

	EffectLogger.log_effect_complete(ctx, self, true)
	return true


func get_description() -> String:
	if not description_override.is_empty():
		return description_override
	return _auto_description()


func get_description_colored(effect_index: int, is_condition_met: bool = true, can_evaluate: bool = true, ctx: EffectContext = null) -> String:
	if not description_override.is_empty():
		return description_override

	var parts: Array[String] = []
	var trigger_prefix = _get_trigger_prefix()

	# Action description (includes ValueResolver text + optional resolved values)
	var action_desc = ""
	if action:
		action_desc = action.get_description_with_context(ctx) if ctx else action.get_description_colored(effect_index)

	# Selector description (colored)
	var selector_desc_colored = ""
	if selector:
		var sel_desc = selector.get_description()
		if not sel_desc.is_empty() and sel_desc != "Self":
			selector_desc_colored = EffectColors.colorize_text(sel_desc, effect_index)

	# Combine action + colored selector
	var main_desc = action_desc
	if not selector_desc_colored.is_empty():
		if "targets" in main_desc:
			main_desc = main_desc.replace("targets", selector_desc_colored)
		elif "target" in main_desc:
			main_desc = main_desc.replace("target", selector_desc_colored)
		else:
			main_desc += " on " + selector_desc_colored

	# Keep base text unchanged; color only the specific domain term to match effect highlight.
	main_desc = _colorize_formation_term(main_desc, effect_index)

	parts.append(main_desc)

	# Trigger prefix
	if not trigger_prefix.is_empty():
		parts.insert(0, trigger_prefix)

	# Condition description (colored green/red/gray)
	if condition:
		var cond_desc = condition.get_description()
		if not cond_desc.is_empty() and cond_desc != "Always":
			var cond_colored = condition.get_description_colored(is_condition_met, can_evaluate)
			var connector = "when" if trigger == GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED else "if"
			parts.append(connector + " " + cond_colored)

	return TooltipFormatter.format(" ".join(parts))


func _colorize_formation_term(text: String, effect_index: int) -> String:
	if text.is_empty():
		return text

	var colored_title = EffectColors.colorize_text("Formação Rochosa", effect_index)
	var colored_lower = EffectColors.colorize_text("formação rochosa", effect_index)

	var result = text.replace("Formação Rochosa", colored_title)
	result = result.replace("formação rochosa", colored_lower)
	return result


func get_all_highlights(ctx: EffectContext) -> Dictionary:
	## Returns {condition: Array[GridSlot], target: Array[GridSlot], value_source: Array[GridSlot]}
	var result = {
		"condition": [],
		"target": [],
		"value_source": []
	}

	if condition:
		result["condition"] = condition.get_highlight_slots(ctx)

	if selector:
		result["target"] = selector.get_preview(ctx)

	if action:
		result["value_source"] = action.get_value_source_slots(ctx)

	return result


func get_keywords() -> Array[StringName]:
	var keywords: Array[StringName] = []
	if condition:
		for kw in condition.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	if selector:
		for kw in selector.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	if action:
		for kw in action.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	return keywords


func get_keywords_display() -> String:
	return Keywords.format_keyword_line(get_keywords())


func _auto_description() -> String:
	var desc = ""
	var trigger_prefix = _get_trigger_prefix()
	if action:
		desc += action.get_description()
	if selector:
		var sel_desc = selector.get_description()
		if not sel_desc.is_empty() and sel_desc != "Self":
			if "targets" in desc:
				desc = desc.replace("targets", sel_desc)
			elif "target" in desc:
				desc = desc.replace("target", sel_desc)
			else:
				desc += " on " + sel_desc
	if not trigger_prefix.is_empty():
		desc = trigger_prefix + " " + desc
	if condition:
		var cond_desc = condition.get_description()
		if not cond_desc.is_empty() and cond_desc != "Always":
			var connector = "when" if trigger == GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED else "if"
			desc += " " + connector + " " + cond_desc
	return desc.strip_edges()


func _get_trigger_prefix() -> String:
	match trigger:
		GameEnums.EffectTrigger.ON_DESTROY:
			return "When destroyed,"
		GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED:
			return "When an adjacent rune is activated,"
		GameEnums.EffectTrigger.ON_CREATED:
			return "When created,"
		GameEnums.EffectTrigger.ON_BUFF_RECEIVED:
			return "When this rune receives a permanent buff,"
		GameEnums.EffectTrigger.ON_ROUND_END:
			return "At end of round,"
		GameEnums.EffectTrigger.ON_ROUND_START:
			return "At start of round,"
		GameEnums.EffectTrigger.ON_ACTIVATED:
			return "When this rune activates,"
	return ""
