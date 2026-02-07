class_name PayloadAddPermanentScoreLastSequence
extends EffectPayload

## Grants permanent score to targets matching the element of the last N activations.
@export var activation_count: int = 5
@export var amount: int = 0

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if amount == 0:
		return
	var common_elements := context.get_common_elements_of_last_n(activation_count)
	if common_elements.is_empty():
		return
	for slot in targets:
		if slot.is_empty():
			continue
		var rune_elements = GameEnums.normalize_elements(slot.rune.get_elements())
		for elem in common_elements:
			if elem in rune_elements:
				apply_score_to_rune(slot.rune, context, amount, true, slot)
				break


func get_description() -> String:
	return "Grant +%d permanent score to runes of repeated element" % [amount]


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE, Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
