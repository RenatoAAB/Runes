class_name ActionScorePerElementHistory
extends EffectAction

## Grants score based on distinct runes of a specific element activated this round.
## Iterates activation_history and counts unique rune IDs with the given element.
## Used by Sacred.

@export var element: GameEnums.Element = GameEnums.Element.SPIRIT
@export var score_per_rune: int = 20


func execute(ctx: EffectContext, _targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, _targets)
	if not ctx or not ctx.battle or not ctx.source_rune:
		return

	var seen: Dictionary = {}
	for entry in ctx.battle.activation_history:
		var elems: Array = entry.get("elements", [])
		if element not in elems:
			continue
		var rune_id: String = entry.get("rune_id", "")
		if rune_id.is_empty():
			rune_id = str(entry.get("rune_instance", null))
		seen[rune_id] = true

	var count = seen.size()
	if count == 0:
		return

	var total = score_per_rune * count
	var final_score = ctx.source_rune.get_modified_score(total)
	ctx.battle.add_score(final_score, ctx.source_rune)
	EffectLogger.log_score(ctx, final_score, ctx.source_rune.data.id if ctx.source_rune.data else "?")


func get_description() -> String:
	var icon = ElementIcons.get_bbcode(element)
	return "+%d score per %s rune activated this round" % [score_per_rune, icon]


func get_description_with_context(ctx: EffectContext) -> String:
	if not ctx or not ctx.battle or not ctx.source_rune:
		return get_description()
	var seen: Dictionary = {}
	for entry in ctx.battle.activation_history:
		var elems: Array = entry.get("elements", [])
		if element not in elems:
			continue
		var rune_id: String = entry.get("rune_id", "")
		if rune_id.is_empty():
			rune_id = str(entry.get("rune_instance", null))
		seen[rune_id] = true
	var count = seen.size()
	if count > 0:
		var total = score_per_rune * count
		var final_score = ctx.source_rune.get_modified_score(total)
		var icon = ElementIcons.get_bbcode(element)
		if final_score != total:
			# External buffs modified the value — highlight in yellow
			return "[color=yellow]+%d[/color] score (%d %s)" % [final_score, count, icon]
		return "+%d score (%d %s)" % [total, count, icon]
	return get_description()


func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE, Keywords.ELEMENT_SYNC, Keywords.SEQUENCE]
