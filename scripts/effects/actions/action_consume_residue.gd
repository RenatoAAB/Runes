class_name ActionConsumeResidue
extends EffectAction

## Consumes a specific residue from target slots.
## Sets source_rune.last_effect_success to indicate if any residue was consumed.
## Used by Spirit runes: Ordem, Caos, Entropia, Mudança, Golem, Empatia, Djinn.

@export var residue_id: String = "mana_residue"
@export var max_consume: int = -1  ## -1 = consume all matching, >0 = limit

## Optional: score per consumed residue
@export var score_per_consumed: ValueResolver
@export var is_permanent: bool = false  ## If true, score is added as permanent buff to source rune


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or residue_id.is_empty():
		return

	var consumed_count = 0
	for slot in targets:
		if max_consume > 0 and consumed_count >= max_consume:
			break
		if not slot or slot.is_void():
			continue
		if slot.slot and slot.slot.has_specific_residue(residue_id):
			slot.slot.clear_residue(residue_id)
			consumed_count += 1
			if ctx.battle and ctx.battle.grid:
				ctx.battle.grid.slot_changed.emit(slot.grid_position)

	if ctx.source_rune:
		ctx.source_rune.last_effect_success = consumed_count > 0

	# Optional: score per consumed
	if score_per_consumed and consumed_count > 0 and ctx.battle:
		var base_amount = score_per_consumed.resolve_int(ctx, targets)
		var total = base_amount * consumed_count
		if is_permanent and ctx.source_rune:
			var current = ctx.source_rune.permanent_buffs.get("score_bonus", 0)
			ctx.source_rune.permanent_buffs["score_bonus"] = current + total
			EffectLogger.log_score(ctx, total, ctx.source_rune.data.id if ctx.source_rune.data else "?")
		else:
			ctx.battle.add_score(total, ctx.source_rune)


func get_description() -> String:
	var res_name = _format_residue_name(residue_id, false)
	var desc = "Consume %s from targets" % res_name
	if max_consume > 0:
		desc = "Consume up to %d %s" % [max_consume, res_name]
	if score_per_consumed:
		var perm_str = " permanent" if is_permanent else ""
		desc += ", %s%s score per consumed" % [score_per_consumed.get_description(), perm_str]
	return desc


func get_keywords() -> Array[StringName]:
	return [Keywords.ABSORB]
