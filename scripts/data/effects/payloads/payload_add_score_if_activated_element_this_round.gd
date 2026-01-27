class_name PayloadAddScoreIfActivatedElementThisRound
extends EffectPayload

## Grants score to target runes that both match an element filter and have activated this round.

@export var amount: int = 0
@export var target_elements: Array[GameEnums.Element] = []

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, context: BattleContext) -> void:
	if amount == 0 or not context:
		return
	for slot in targets:
		if slot.is_empty():
			continue
		var rune := slot.rune
		if not _matches_element_filter(rune):
			continue
		if not _has_activated_this_round(rune, context):
			continue
		apply_score_to_rune(rune, context, amount, false)


func _matches_element_filter(rune: RuneInstance) -> bool:
	if target_elements.is_empty():
		return true
	var elems = GameEnums.normalize_elements(rune.data.elements)
	for e in target_elements:
		if e in elems:
			return true
	return false


func _has_activated_this_round(rune: RuneInstance, context: BattleContext) -> bool:
	for entry in context.activation_history:
		if entry.get("rune_instance", null) == rune:
			return true
	return false


func get_description() -> String:
	var elem_str = ElementIcons.join(target_elements) if target_elements.size() > 0 else "any"
	return "+%d score to %s runes activated this round" % [amount, elem_str]


func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE, Keywords.ELEMENT_TARGET, Keywords.SEQUENCE]
