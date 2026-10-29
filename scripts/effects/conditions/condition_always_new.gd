class_name ConditionAlwaysNew
extends NewEffectCondition

## Always true. Used when no condition is needed.

func evaluate(_ctx: EffectContext) -> bool:
	return true


func get_description() -> String:
	return "Always"


func is_gameplay_condition() -> bool:
	return false
