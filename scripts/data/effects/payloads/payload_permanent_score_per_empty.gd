class_name PayloadPermanentScorePerEmpty
extends EffectPayload

## Grants permanent score based on how many empty target slots are provided.

@export var amount_per_empty: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var empty_count := 0
	for slot in targets:
		if slot.is_void():
			continue
		if slot.is_empty():
			empty_count += 1
	if empty_count == 0:
		return
	apply_score(empty_count * amount_per_empty, source_rune, context, true)


func get_description() -> String:
	return "Gain +%d permanent score per empty target slot" % amount_per_empty


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.NEIGHBORS]
