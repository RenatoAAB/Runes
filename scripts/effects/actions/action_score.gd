class_name ActionScore
extends EffectAction

## Adds score using ValueResolver. Supports permanent/temporary and source/each_target application.

enum ApplyMode {
	SOURCE,       ## Apply resolved score once, from source rune
	EACH_TARGET,  ## Apply resolved score per target rune
}

@export var value: ValueResolver
@export var is_permanent: bool = false
@export var apply_mode: ApplyMode = ApplyMode.SOURCE


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not value or not ctx:
		return

	match apply_mode:
		ApplyMode.SOURCE:
			var amount = value.resolve_int(ctx, targets)
			if amount == 0:
				return
			_apply(amount, ctx.source_rune, ctx, ctx.source_slot)
		ApplyMode.EACH_TARGET:
			for slot in targets:
				if slot.is_empty():
					continue
				var amount = value.resolve_int(ctx, targets)
				if amount == 0:
					continue
				_apply(amount, slot.rune, ctx, slot)


func _apply(amount: int, rune: RuneInstance, ctx: EffectContext, slot: GridSlot) -> void:
	if is_permanent:
		var mult = _get_enhancer_multiplier(slot)
		var final_amount = amount * mult
		var current = rune.permanent_buffs.get("score_bonus", 0)
		rune.permanent_buffs["score_bonus"] = current + final_amount
		EffectLogger.log_score(ctx, final_amount, rune.data.id if rune.data else "?")
	else:
		var final_score = rune.get_modified_score(amount)
		ctx.battle.add_score(final_score, rune)
		EffectLogger.log_score(ctx, final_score, rune.data.id if rune.data else "?")


func get_description() -> String:
	if not value:
		return ""
	var val_desc = value.get_description()
	var perm_str = " permanent" if is_permanent else ""
	return "%s%s Score" % [val_desc, perm_str]


func get_description_with_context(ctx: EffectContext) -> String:
	if not value or not ctx or not ctx.source_rune or not ctx.battle:
		return get_description()
	var perm_str = " permanent" if is_permanent else ""
	var resolved = value.resolve_int(ctx)
	if is_permanent:
		# Permanent scores: only show resolved value if per[] changed it (no yellow)
		if value.per.is_empty() or resolved == int(value.base):
			return get_description()
		var prefix = "+" if resolved > 0 else ""
		return "%s%d%s Score" % [prefix, resolved, perm_str]
	# Non-permanent: resolve and apply rune score modifiers
	var display_value = resolved
	if apply_mode == ApplyMode.SOURCE:
		display_value = ctx.source_rune.get_modified_score(resolved)
	var has_external_buff = (display_value != resolved)
	if has_external_buff:
		# External buffs modified the value — highlight in yellow
		var prefix = "+" if display_value > 0 else ""
		return "[color=yellow]%s%d[/color] Score" % [prefix, display_value]
	if resolved != int(value.base):
		# Per[] changed value but no external buff — show plain resolved value
		var prefix = "+" if resolved > 0 else ""
		return "%s%d Score" % [prefix, resolved]
	return get_description()


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not value:
		return []
	return value.get_source_slots(ctx)


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.SCORE]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
