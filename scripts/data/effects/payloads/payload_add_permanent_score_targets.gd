class_name PayloadAddPermanentScoreTargets
extends EffectPayload

## Adds a flat permanent score bonus to each target rune that matches the filter.
## Useful for auras like Rock: "adjacent Earth runes gain +X permanent score".

@export var amount: int = 0
@export var target_elements: Array[GameEnums.Element] = [] ## Empty = no element filter (all runes)

func execute(targets: Array[GridSlot], _source_rune: RuneInstance, _context: BattleContext) -> void:
	if amount == 0:
		return
	for slot in targets:
		if slot.is_empty():
			continue
		if not _matches_element_filter(slot):
			continue
		apply_score_to_rune(slot.rune, _context, amount, true)


func _matches_element_filter(slot: GridSlot) -> bool:
	if target_elements.is_empty():
		return true
	var elems = GameEnums.normalize_elements(slot.rune.get_elements())
	for e in target_elements:
		if e in elems:
			return true
	return false


func get_description() -> String:
	var elem_str = ElementIcons.join(target_elements) if target_elements.size() > 0 else "any"
	return "Grant +%d permanent score to %s targets" % [amount, elem_str]


func get_keywords() -> Array[StringName]:
	return [Keywords.PERMANENT, Keywords.SCORE]
