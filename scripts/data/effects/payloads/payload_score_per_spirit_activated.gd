class_name PayloadScorePerSpiritActivated
extends EffectPayload

## Grants score based on distinct Spirit runes that activated this round.

const ElementIcons = preload("res://scripts/core/element_icons.gd")

@export var amount_per_rune: int = 20

func execute(_targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	if not context or amount_per_rune == 0:
		return
	var seen: Dictionary = {}
	for entry in context.activation_history:
		var elems: Array[GameEnums.Element] = entry.get("elements", [])
		if GameEnums.Element.SPIRIT not in elems:
			continue
		var rune_id: String = entry.get("rune_id", "")
		if rune_id.is_empty():
			rune_id = str(entry.get("rune_instance", null))
		seen[rune_id] = true
	var count = seen.size()
	if count == 0:
		return
	apply_score(amount_per_rune * count, source_rune, context, false)


func get_description() -> String:
	var spirit_icon = ElementIcons.get_bbcode(GameEnums.Element.SPIRIT)
	return "+%d score per %s rune activated this round" % [amount_per_rune, spirit_icon]


func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE, Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
