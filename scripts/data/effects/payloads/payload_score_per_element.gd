class_name PayloadScorePerElement
extends EffectPayload

## Adds score for each rune of specified element(s) in the targets.
## Highly flexible - can be used for adjacency bonuses, panel-wide bonuses, etc.
## The score can be positive or negative.

@export var score_per_match: int = 10
@export var target_elements: Array[GameEnums.Element] = []
@export var check_base_elements: bool = true  ## If true, checks element composition (e.g., LAVA matches FIRE)
@export var is_permanent: bool = false  ## If true, adds to permanent buffs instead of immediate score

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var match_count = 0
	
	for slot in targets:
		if slot.is_empty():
			continue
		
		var rune_element = slot.rune.data.element
		var is_match = false
		
		if check_base_elements:
			# Check if the rune's base elements include any target element
			var base_elements = GameEnums.get_base_elements(rune_element)
			for target_elem in target_elements:
				if target_elem in base_elements:
					is_match = true
					break
		else:
			# Direct element match only
			is_match = rune_element in target_elements
		
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
	var elem_names: Array[String] = []
	for elem in target_elements:
		elem_names.append(GameEnums.Element.keys()[elem].capitalize())
	
	var perm_str = " permanent" if is_permanent else ""
	var sign = "+" if score_per_match >= 0 else ""
	return "%s%d%s Score per %s" % [sign, score_per_match, perm_str, " or ".join(elem_names)]


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.SCORE]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
