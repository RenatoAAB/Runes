class_name PayloadScorePerEmpty
extends EffectPayload

## Adds score for each empty adjacent slot.

@export var score_per_empty: int = 50

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var empty_count = 0
	for slot in targets:
		if slot.is_empty():
			empty_count += 1
	
	if empty_count > 0:
		var total = empty_count * score_per_empty
		var final_score = source_rune.get_modified_score(total)
		context.add_score(final_score, source_rune)
		print("Space: Added %d score for %d empty slots" % [final_score, empty_count])

func get_description() -> String:
	return "+%d Score per empty adjacent slot" % score_per_empty

func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE, Keywords.NEIGHBORS]
