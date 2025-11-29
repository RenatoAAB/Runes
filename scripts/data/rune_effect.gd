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
