class_name ConditionSimultaneousActivation
extends NewEffectCondition

## Checks if the source rune was activated as part of a simultaneous batch
## (e.g., triggered by Redemoinho, Furacão, Raio, Geada).
## Used by Eletricidade and Sedimentação.


func evaluate(ctx: EffectContext) -> bool:
	if not ctx or not ctx.battle or not ctx.source_rune:
		return false
	return ctx.battle.is_simultaneous_active()


func get_description() -> String:
	return "activated simultaneously"


func get_keywords() -> Array[StringName]:
	return [Keywords.TRIGGER]
