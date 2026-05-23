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
@export var emit_buff_received_event: bool = true


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not value or not ctx:
		return

	match apply_mode:
		ApplyMode.SOURCE:
			var amount = value.resolve_int(ctx, targets)
			_apply(amount, ctx.source_rune, ctx, ctx.source_slot, targets)
		ApplyMode.EACH_TARGET:
			for slot in targets:
				if slot.is_empty():
					continue
				var amount = value.resolve_int(ctx, targets)
				_apply(amount, slot.rune, ctx, slot, targets)


func _apply(amount: int, rune: RuneInstance, ctx: EffectContext, slot: GridSlot, targets: Array[GridSlot] = []) -> void:
	if not rune:
		return
	if is_permanent:
		var mult = _get_enhancer_multiplier(slot)
		var final_amount = amount * mult
		if final_amount == 0:
			return
		var current = rune.permanent_buffs.get("score_bonus", 0)
		rune.permanent_buffs["score_bonus"] = current + final_amount
		EffectLogger.log_score(ctx, final_amount, rune.data.id if rune.data else "?")
		# Notify reactive passives (e.g. Topázio — ON_BUFF_RECEIVED)
		if emit_buff_received_event and slot and rune:
			EventBus.notify_buff_received(slot, rune)
	else:
		var final_score = _resolve_temporary_score(amount, rune, ctx, targets)
		if final_score == 0:
			return
		ctx.battle.add_score(final_score, rune)
		EffectLogger.log_score(ctx, final_score, rune.data.id if rune.data else "?")


func _is_pure_counter_score() -> bool:
	return value and value.base == 0.0 and not value.per.is_empty()


func _count_counter_units(ctx: EffectContext, targets: Array[GridSlot]) -> int:
	if not value:
		return 0
	var units := 0
	for vp in value.per:
		if not vp:
			continue
		var cnt = vp.count(ctx, targets)
		if cnt > 0:
			units += cnt
	return units


func get_description() -> String:
	if not value:
		return ""
	var perm_str = " permanent" if is_permanent else ""
	var base_str = value.get_base_str()
	var per_str = value.get_per_str()
	var mult_str = " (×%.1f)" % value.final_multiplier if value.final_multiplier != 1.0 else ""
	if base_str.is_empty() and not value.per.is_empty():
		# Only per[] provides value — build each entry as "+10 permanent Score per condition"
		var parts: Array[String] = []
		for vp in value.per:
			if not vp:
				continue
			var prefix = "+" if vp.per_value > 0 else ""
			var val_str := "%s%d" % [prefix, int(vp.per_value)] if vp.per_value == int(vp.per_value) else "%s%.1f" % [prefix, vp.per_value]
			parts.append("%s%s Score per %s" % [val_str, perm_str, vp.get_description()])
		return " ".join(parts) + mult_str
	elif per_str.is_empty():
		return "%s%s Score%s" % [base_str, perm_str, mult_str]
	else:
		return "%s%s Score %s%s" % [base_str, perm_str, per_str, mult_str]


func get_description_with_context(ctx: EffectContext) -> String:
	if not value or not ctx or not ctx.source_rune or not ctx.battle:
		return get_description()
	if is_permanent:
		return get_description()
	# Non-permanent: resolve to show effect of external buffs (e.g. Enhancer slots)
	var resolved = value.resolve_int(ctx)
	var display_value = resolved
	if apply_mode == ApplyMode.SOURCE:
		display_value = _resolve_temporary_score(resolved, ctx.source_rune, ctx, [])

	if apply_mode == ApplyMode.SOURCE and _is_pure_counter_score():
		var score_bonus = _get_total_score_bonus(ctx.source_rune)
		if score_bonus != 0 and value.per.size() == 1 and value.per[0]:
			var vp = value.per[0]
			var adjusted_per = vp.per_value + score_bonus
			var units = max(0, vp.count(ctx, []))
			var per_prefix = "+" if adjusted_per > 0 else ""
			var per_str := "%s%d" % [per_prefix, int(adjusted_per)] if adjusted_per == int(adjusted_per) else "%s%.1f" % [per_prefix, adjusted_per]
			var total_prefix = "+" if display_value > 0 else ""
			return "[color=yellow]%s[/color] Score per %s (total: %s%d)" % [per_str, vp.get_description(), total_prefix, display_value]

	var has_external_buff = (display_value != resolved)
	if has_external_buff:
		# External buffs modified the value — highlight in yellow
		var prefix = "+" if display_value > 0 else ""
		return "[color=yellow]%s%d[/color] Score" % [prefix, display_value]
	return get_description()


func _resolve_temporary_score(amount: int, rune: RuneInstance, ctx: EffectContext, targets: Array[GridSlot]) -> int:
	if _is_pure_counter_score() and value:
		var units = _count_counter_units(ctx, targets)
		if units <= 0:
			return 0
		var score_bonus = _get_total_score_bonus(rune)
		var score_mult = _get_total_score_multiplier(rune)
		return int((amount + score_bonus * units) * score_mult)
	return rune.get_modified_score(amount)


func _get_total_score_bonus(rune: RuneInstance) -> int:
	if not rune:
		return 0
	return rune.stat_modifiers.get("score_bonus", 0) + rune.permanent_buffs.get("score_bonus", 0)


func _get_total_score_multiplier(rune: RuneInstance) -> float:
	if not rune:
		return 1.0
	return rune.stat_modifiers.get("score_multiplier", 1.0) * rune.permanent_buffs.get("score_multiplier", 1.0)


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not value:
		return []
	return value.get_source_slots(ctx)


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.SCORE]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
