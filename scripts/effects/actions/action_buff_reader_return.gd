class_name ActionBuffReaderReturn
extends EffectAction

## Buffs how many extra steps the reader rewinds when this rune executes rewind effects.

@export var value: ValueResolver
@export var is_permanent: bool = false


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not value or not ctx:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		var amount = value.resolve_int(ctx, targets)
		var mult = _get_enhancer_multiplier(slot)
		var final_bonus = amount * mult

		if is_permanent:
			var current = target_rune.permanent_buffs.get("reader_return_bonus", 0)
			target_rune.permanent_buffs["reader_return_bonus"] = current + final_bonus
			EventBus.notify_buff_received(slot, target_rune)
		else:
			var current = target_rune.stat_modifiers.get("reader_return_bonus", 0)
			target_rune.stat_modifiers["reader_return_bonus"] = current + final_bonus


func get_description() -> String:
	if not value:
		return ""
	var val_desc = value.get_description()
	var perm_str = " permanent" if is_permanent else ""
	return "%s%s Reader return to targets" % [val_desc, perm_str]


func get_description_with_context(ctx: EffectContext) -> String:
	if not value or not ctx or not ctx.battle:
		return get_description()
	if value.per.is_empty():
		return get_description()
	var resolved = value.resolve_int(ctx)
	if resolved == int(value.base):
		return get_description()
	var prefix = "+" if resolved > 0 else ""
	var perm_str = " permanent" if is_permanent else ""
	return "%s%d%s Reader return to targets" % [prefix, resolved, perm_str]


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not value:
		return []
	return value.get_source_slots(ctx)


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.BUFF, Keywords.MOVE]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
