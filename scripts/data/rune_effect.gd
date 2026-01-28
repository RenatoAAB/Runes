class_name RuneEffect
extends Resource

## Modular rune effect composed of: Trigger (WHEN), Condition (IF), Target (WHO), Payload (WHAT).
## 
## Trigger: When should this effect execute?
## Condition: Should the effect execute given current state?
## Target: Which slots/runes are affected?
## Payload: What action is performed?

@export var trigger: GameEnums.EffectTrigger = GameEnums.EffectTrigger.ON_READ
@export var condition: EffectCondition
@export var target: EffectTarget
@export var payload: EffectPayload

## Executes this effect if condition is met.
## Called by the trigger system at the appropriate time.
func execute(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> void:
	if not condition or not target or not payload:
		push_warning("RuneEffect missing components.")
		source_rune.last_effect_success = false
		return

	var condition_met = condition.evaluate(source_rune, context, source_slot)
	if source_slot and source_slot.slot and source_slot.slot.data and source_slot.slot.data.id == "slot_refractor":
		condition_met = true
	if condition_met:
		var targets = target.get_targets(source_rune, context, source_slot)
		if targets.size() > 0:
			payload.execute(targets, source_rune, context)
			source_rune.last_effect_success = true
		else:
			source_rune.last_effect_success = false
	else:
		source_rune.last_effect_success = false

## Returns a plain text description of this effect.
func get_description() -> String:
	var desc = ""
	var trigger_prefix = _get_trigger_prefix(trigger)
	if payload and payload.has_method("get_description"):
		desc += payload.get_description()
	
	# Append target description if it's specific (not just implied by payload)
	# We can check if target has a meaningful description.
	if target and target.has_method("get_description"):
		var target_desc = target.get_description()
		
		# Simple heuristic: if target description is not empty and not just "Self"
		if target_desc != "" and target_desc != "Self":
			# If the payload description contains the word "targets", replace it for better flow.
			if "targets" in desc:
				desc = desc.replace("targets", target_desc)
			else:
				desc += " on " + target_desc

	if trigger_prefix != "":
		desc = (trigger_prefix + " " + desc).strip_edges()
	if condition and condition.has_method("get_description"):
		var connector = "when" if trigger == GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED else "if"
		desc += " " + connector + " " + condition.get_description()
	return desc

## Returns a BBCode-formatted description with colors matching the grid visualization.
## effect_index: the index of this effect in the rune's effect array (for color coordination)
## is_condition_met: whether the condition is currently satisfied (for condition coloring)
## can_evaluate_condition: whether we can evaluate the condition (false if in inventory)
func get_description_colored(effect_index: int, is_condition_met: bool = true, can_evaluate_condition: bool = true) -> String:
	var parts: Array[String] = []
	var trigger_prefix = _get_trigger_prefix(trigger)
	
	# 1. Payload description (plain text)
	var payload_desc = ""
	if payload and payload.has_method("get_description"):
		payload_desc = payload.get_description()
	
	# 2. Target description (colored with effect color)
	var target_desc_colored = ""
	if target and target.has_method("get_description"):
		var target_desc = target.get_description()
		if target_desc != "" and target_desc != "Self":
			target_desc_colored = EffectColors.colorize_text(target_desc, effect_index)
	
	# 3. Combine payload with colored target
	var main_desc = payload_desc
	if target_desc_colored != "":
		if "targets" in main_desc:
			main_desc = main_desc.replace("targets", target_desc_colored)
		elif "target" in main_desc:
			main_desc = main_desc.replace("target", target_desc_colored)
		else:
			main_desc += " on " + target_desc_colored
	
	parts.append(main_desc)
	
	# 4. Condition description (colored based on whether it's met)
	if trigger_prefix != "":
		parts.append(trigger_prefix)
	if condition and condition.has_method("get_description"):
		var cond_desc = condition.get_description()
		if cond_desc != "" and cond_desc != "Always":
			var cond_colored = condition.get_description_colored(is_condition_met, can_evaluate_condition)
			var connector = "when" if trigger == GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED else "if"
			parts.append(connector + " " + cond_colored)
	
	return " ".join(parts)


func _get_trigger_prefix(effect_trigger: GameEnums.EffectTrigger) -> String:
	match effect_trigger:
		GameEnums.EffectTrigger.ON_DESTROY:
			return "When destroyed,".strip_edges()
		GameEnums.EffectTrigger.ON_ADJACENT_ACTIVATED:
			return "When an adjacent rune is activated,".strip_edges()
		GameEnums.EffectTrigger.ON_CREATED:
			return "When created,".strip_edges()
		GameEnums.EffectTrigger.ON_ROUND_END:
			return "At end of round,".strip_edges()
		GameEnums.EffectTrigger.ON_ROUND_START:
			return "At start of round,".strip_edges()
		GameEnums.EffectTrigger.ON_ACTIVATED:
			return "When this rune activates,".strip_edges()
		_:
			return ""


## Returns all keywords from this effect (aggregated from condition, target, and payload).
func get_keywords() -> Array[StringName]:
	var keywords: Array[StringName] = []
	
	if condition and condition.has_method("get_keywords"):
		for kw in condition.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	
	if target and target.has_method("get_keywords"):
		for kw in target.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	
	if payload and payload.has_method("get_keywords"):
		for kw in payload.get_keywords():
			if kw not in keywords:
				keywords.append(kw)
	
	return keywords


## Returns a formatted string of keyword badges for display.
func get_keywords_display() -> String:
	return Keywords.format_keyword_line(get_keywords())
