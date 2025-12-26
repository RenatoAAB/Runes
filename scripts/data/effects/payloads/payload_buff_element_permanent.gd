class_name PayloadBuffElementPermanent
extends EffectPayload

## Permanently buffs all runes of a specific element.

@export var target_element: GameEnums.Element = GameEnums.Element.EARTH
@export var score_bonus: int = 10

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	for slot in context.grid.grid:
		if not slot.is_empty():
			if slot.rune.data.element == target_element:
				slot.rune.permanent_buffs["score_bonus"] = slot.rune.permanent_buffs.get("score_bonus", 0) + score_bonus
				print("Buffed %s element rune %s by +%d" % [GameEnums.Element.keys()[target_element], slot.rune.data.rune_name, score_bonus])

func get_description() -> String:
	return "All %s runes gain +%d permanent Score" % [GameEnums.Element.keys()[target_element], score_bonus]

func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.SCALING, Keywords.ELEMENT_TARGET]
