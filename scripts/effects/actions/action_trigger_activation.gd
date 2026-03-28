class_name ActionTriggerActivation
extends EffectAction

## Immediately activates target runes (triggers their effects).
## When simultaneous=true, all targets are activated within a simultaneous batch,
## which other conditions/effects can detect.

@export var simultaneous: bool = false
## If true, activate ALL remaining activations of each target (Pressão)
@export var drain_all_activations: bool = false


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx or not ctx.battle:
		return

	if simultaneous and ctx.battle:
		ctx.battle.begin_simultaneous_batch()

	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		if drain_all_activations:
			# Activate all remaining times
			while target_rune.can_activate():
				target_rune.on_activate(ctx.battle, slot)
				if ctx.battle:
					ctx.battle.record_activation(target_rune, slot)
		else:
			if target_rune.can_activate():
				target_rune.on_activate(ctx.battle, slot)
				if ctx.battle:
					ctx.battle.record_activation(target_rune, slot)

	if simultaneous and ctx.battle:
		ctx.battle.end_simultaneous_batch()


func get_description() -> String:
	if drain_all_activations:
		return "Activate all remaining activations of target runes"
	if simultaneous:
		return "Activate target runes simultaneously"
	return "Activate target runes"


func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER]
