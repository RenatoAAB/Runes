class_name ActionTriggerOrBuffActivation
extends EffectAction

## Per-rune OR logic: if the rune can activate → activates it (simultaneous batch);
## if it has 0 remaining activations → grants +buff_amount charge instead.
## Used by Geada: the two branches are mutually exclusive at evaluation time,
## so sequential-state corruption cannot occur.

@export var simultaneous: bool = false
@export var buff_amount: int = 1


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	if simultaneous:
		ctx.battle.begin_simultaneous_batch()

	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		if target_rune.can_activate():
			target_rune.on_activate(ctx.battle, slot)
			if ctx.battle:
				ctx.battle.record_activation(target_rune, slot)
		else:
			var mult = _get_enhancer_multiplier(slot)
			var current = target_rune.stat_modifiers.get("activation_bonus", 0)
			target_rune.stat_modifiers["activation_bonus"] = current + buff_amount * mult

	if simultaneous:
		ctx.battle.end_simultaneous_batch()


func get_description() -> String:
	return "Activate targets simultaneously; targets runes with no charges receive +%d charge instead" % buff_amount


func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER, Keywords.BUFF, Keywords.CHARGED]
