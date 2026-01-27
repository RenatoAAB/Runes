class_name PayloadMarkResurrection
extends EffectPayload

## Marks the source rune to resurrect at the same slot at round end, granting a permanent score bonus.

@export var permanent_score_bonus: int = 0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context:
		return
	# Use the source slot (self target) to preserve the original position.
	if targets.is_empty():
		return
	var slot := targets[0]
	context.mark_for_resurrection(source_rune, slot, permanent_score_bonus)


func get_description() -> String:
	return "If destroyed, resurrect at round end with +%d permanent score" % permanent_score_bonus


func get_keywords() -> Array[StringName]:
	return [Keywords.CREATE, Keywords.PERMANENT, Keywords.SCORE]
