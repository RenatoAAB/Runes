class_name RuneEffect
extends Resource

## Base class for all modular rune effects.
## Composed of a Condition, a Target, and a Payload.

@export var condition: EffectCondition
@export var target: EffectTarget
@export var payload: EffectPayload

# We use 'Object' for source_rune and grid_manager to avoid cyclic dependency issues 
# during the initial setup, but these will be typed as RuneInstance and GridManager later.
# Actually, since we are in GDScript 2.0 (Godot 4), we can use class_name types if we are careful,
# but to be safe with the current file structure, we will cast them inside.
func execute(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> void:
	if not condition or not target or not payload:
		push_warning("RuneEffect missing components.")
		source_rune.last_effect_success = false
		return

	if condition.evaluate(source_rune, context, source_slot):
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

	if condition and condition.has_method("get_description"):
		desc += " if " + condition.get_description()
	return desc

## Returns a BBCode-formatted description with colors matching the grid visualization.
## effect_index: the index of this effect in the rune's effect array (for color coordination)
## is_condition_met: whether the condition is currently satisfied (for condition coloring)
## can_evaluate_condition: whether we can evaluate the condition (false if in inventory)
func get_description_colored(effect_index: int, is_condition_met: bool = true, can_evaluate_condition: bool = true) -> String:
	var parts: Array[String] = []
	
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
	if condition and condition.has_method("get_description"):
		var cond_desc = condition.get_description()
		if cond_desc != "" and cond_desc != "Always":
			var cond_colored = condition.get_description_colored(is_condition_met, can_evaluate_condition)
			parts.append("if " + cond_colored)
	
	return " ".join(parts)
