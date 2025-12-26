class_name ConditionMoney
extends EffectCondition

## Checks if the player has a certain amount of money.
## Per GDD: "Jogador tem mais/menos que X dinheiro."

enum ComparisonType {
	AT_LEAST,      ## Has >= X money
	LESS_THAN,     ## Has < X money
	EXACTLY,       ## Has exactly X money
	MULTIPLE_OF,   ## Money is multiple of X
}

@export var comparison: ComparisonType = ComparisonType.AT_LEAST
@export var amount: int = 5

func evaluate(source_rune: RuneInstance, context: BattleContext, source_slot: GridSlot) -> bool:
	var current_money = context.get_money()
	
	match comparison:
		ComparisonType.AT_LEAST:
			return current_money >= amount
		ComparisonType.LESS_THAN:
			return current_money < amount
		ComparisonType.EXACTLY:
			return current_money == amount
		ComparisonType.MULTIPLE_OF:
			return amount > 0 and current_money % amount == 0
	
	return false

func get_description() -> String:
	match comparison:
		ComparisonType.AT_LEAST:
			return "If you have at least $%d" % amount
		ComparisonType.LESS_THAN:
			return "If you have less than $%d" % amount
		ComparisonType.EXACTLY:
			return "If you have exactly $%d" % amount
		ComparisonType.MULTIPLE_OF:
			return "If your money is a multiple of %d" % amount
	return ""

func get_keywords() -> Array[StringName]:
	return [Keywords.RESOURCE, Keywords.THRESHOLD]
