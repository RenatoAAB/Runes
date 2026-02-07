class_name EffectPayload
extends Resource

## Base class for the actual action performed by the effect.

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	pass

## Returns a plain text description of this payload.
func get_description() -> String:
	return ""

## Returns a BBCode-formatted description.
## The target_desc should already be colored if needed.
func get_description_with_target(target_desc: String) -> String:
	var desc = get_description()
	if target_desc.is_empty():
		return desc
	
	# Replace "targets" or "target" with the actual target description
	if "targets" in desc:
		return desc.replace("targets", target_desc)
	elif "target" in desc:
		return desc.replace("target", target_desc)
	else:
		# Append target info if no placeholder
		return desc + " on " + target_desc

## Returns the keywords associated with this payload.
## Override in subclasses to return specific keywords.
func get_keywords() -> Array[StringName]:
	return []


## Returns buff multiplier for runes in an Enhancer slot.
func _get_enhancer_multiplier(target_slot: GridSlot) -> int:
	if not target_slot or not target_slot.slot or not target_slot.slot.data:
		return 1
	return 2 if target_slot.slot.data.id == "slot_enhancer" else 1


## Unified helper to apply score or permanent bonus
func apply_score(amount: int, source_rune: RuneInstance, context: BattleContext, is_permanent: bool) -> void:
	if amount == 0:
		return
	if is_permanent:
		var mult = _get_enhancer_multiplier(context.current_slot if context else null)
		var final_amount = amount * mult
		# Permanent score gains ignore temporary/permanent score multipliers/bonuses
		var current = source_rune.permanent_buffs.get("score_bonus", 0)
		source_rune.permanent_buffs["score_bonus"] = current + final_amount
	else:
		var final_score = source_rune.get_modified_score(amount)
		context.add_score(final_score, source_rune)


## Helper to apply score/permanent bonus to an arbitrary rune (used for aura effects)
func apply_score_to_rune(target_rune: RuneInstance, context: BattleContext, amount: int, is_permanent: bool, target_slot: GridSlot = null) -> void:
	if amount == 0 or not target_rune:
		return
	if is_permanent:
		var mult = _get_enhancer_multiplier(target_slot)
		var final_amount = amount * mult
		# Permanent score gains ignore temporary/permanent score multipliers/bonuses
		var current = target_rune.permanent_buffs.get("score_bonus", 0)
		target_rune.permanent_buffs["score_bonus"] = current + final_amount
	else:
		var final_score = target_rune.get_modified_score(amount)
		context.add_score(final_score, target_rune)
