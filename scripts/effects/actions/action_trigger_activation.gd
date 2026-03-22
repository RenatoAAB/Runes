class_name ActionTriggerActivation
extends EffectAction

## Immediately activates target runes (triggers their effects).

func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		if target_rune.can_activate():
			target_rune.on_activate(ctx.battle, slot)


func get_description() -> String:
	return "Activate target runes"


func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER]
