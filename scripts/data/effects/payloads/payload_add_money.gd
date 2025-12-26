class_name PayloadAddMoney
extends EffectPayload

## Adds money to the player's balance.
## Per GDD: "Gere ou perca $ Dinheiro ao ser ativada."

@export var amount: int = 1  ## Amount of money to add

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	context.add_money(amount, source_rune)

func get_description() -> String:
	if amount >= 0:
		return "Gain $%d" % amount
	else:
		return "Lose $%d" % abs(amount)

func get_keywords() -> Array[StringName]:
	return [Keywords.INCOME]
