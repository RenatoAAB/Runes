class_name ActionScoreMatchingSequenceElement
extends EffectAction

## Grants permanent score to target runes whose element matches the common
## element of the last N activations. Used by Stagnation.

@export var activation_count: int = 5
@export var amount: int = 10


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle or amount == 0:
		return

	var common_elements := ctx.battle.get_common_elements_of_last_n(activation_count)
	if common_elements.is_empty():
		return

	for slot in targets:
		if slot.is_empty():
			continue
		var rune_elements = GameEnums.normalize_elements(slot.rune.get_elements())
		for elem in common_elements:
			if elem in rune_elements:
				var mult = _get_enhancer_multiplier(slot)
				var final_amount = amount * mult
				var current = slot.rune.permanent_buffs.get("score_bonus", 0)
				slot.rune.permanent_buffs["score_bonus"] = current + final_amount
				EffectLogger.log_score(ctx, final_amount, slot.rune.data.id if slot.rune.data else "?")
				break


func get_description() -> String:
	return "+%d permanent score to runes of repeated element" % amount


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.ELEMENT_SYNC]
