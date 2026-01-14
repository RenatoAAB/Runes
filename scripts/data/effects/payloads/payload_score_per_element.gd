class_name PayloadScorePerElement
extends EffectPayload

const ElementIcons = preload("res://scripts/core/element_icons.gd")

## Adds score for each rune of specified element(s) in the targets.
## Highly flexible - can be used for adjacency bonuses, panel-wide bonuses, etc.
## The score can be positive or negative.

@export var score_per_match: int = 10
@export var target_elements: Array[GameEnums.Element] = []
@export var is_permanent: bool = false  ## If true, adds to permanent buffs instead of immediate score

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var match_count = 0
	
	for slot in targets:
		if slot.is_empty():
			continue
		
		var rune_elements = GameEnums.normalize_elements(slot.rune.data.elements)
		var is_match = false
		
		for target_elem in target_elements:
			if target_elem in rune_elements:
				is_match = true
				break
		
		if is_match:
			match_count += 1
	
	if match_count == 0:
		return
	
	var total = match_count * score_per_match
	
	if is_permanent:
		var current_bonus = source_rune.permanent_buffs.get("score_bonus", 0)
		source_rune.permanent_buffs["score_bonus"] = current_bonus + total
		print("%s: +%d permanent score (%d × %d matches)" % [source_rune.data.rune_name, total, score_per_match, match_count])
	else:
		var final_score = source_rune.get_modified_score(total)
		context.add_score(final_score, source_rune)
		print("%s: +%d score (%d × %d matches)" % [source_rune.data.rune_name, final_score, score_per_match, match_count])


func get_description() -> String:
	var elems_str = ElementIcons.join(target_elements)
	var perm_str = " permanent" if is_permanent else ""
	var sign = "+" if score_per_match >= 0 else ""
	return "%s%d%s Score per %s" % [sign, score_per_match, perm_str, elems_str]


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.SCORE]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
