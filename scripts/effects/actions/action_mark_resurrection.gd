class_name ActionMarkResurrection
extends EffectAction

## Marks the source rune to resurrect at end of round.
## Used by Phoenix-type effects.

@export var permanent_score_bonus: int = 0


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle or not ctx.source_rune or not ctx.source_slot:
		return

	ctx.battle.mark_for_resurrection(ctx.source_rune, ctx.source_slot, permanent_score_bonus)


func get_description() -> String:
	var desc = "Resurrect at end of round"
	if permanent_score_bonus > 0:
		desc += " with +%d permanent score" % permanent_score_bonus
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE]
