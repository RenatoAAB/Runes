class_name ActionMultiplyGlobalScore
extends EffectAction

## Multiplies the global score by a factor resolved via ValueResolver.
## Used primarily by relics.

@export var value: ValueResolver


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not value or not ctx or not ctx.battle:
		return

	var factor = value.resolve(ctx, targets)
	if factor != 1.0:
		ctx.battle.multiply_global_score(factor)


func get_description() -> String:
	if not value:
		return ""
	return "×%s global score" % value.get_description()


func get_value_source_slots(ctx: EffectContext) -> Array[GridSlot]:
	if not value:
		return []
	return value.get_source_slots(ctx)


func get_keywords() -> Array[StringName]:
	return [Keywords.SCORE]
