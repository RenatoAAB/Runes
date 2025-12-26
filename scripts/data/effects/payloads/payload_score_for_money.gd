class_name PayloadScoreForMoney
extends EffectPayload

## Converts score to money or vice versa.
## Per GDD: "Runas que subtraem pontuação mas dão dinheiro."

enum ConversionType {
	SCORE_TO_MONEY,  ## Lose score, gain money
	MONEY_TO_SCORE,  ## Spend money, gain score
}

@export var conversion_type: ConversionType = ConversionType.SCORE_TO_MONEY
@export var score_amount: int = 10
@export var money_amount: int = 1

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	match conversion_type:
		ConversionType.SCORE_TO_MONEY:
			# Lose score, gain money
			context.add_score(-score_amount, source_rune)
			context.add_money(money_amount, source_rune)
		
		ConversionType.MONEY_TO_SCORE:
			# Try to spend money for score
			if context.remove_money(money_amount, source_rune):
				context.add_score(score_amount, source_rune)
				source_rune.last_effect_success = true
			else:
				source_rune.last_effect_success = false

func get_description() -> String:
	match conversion_type:
		ConversionType.SCORE_TO_MONEY:
			return "Lose %d score, gain $%d" % [score_amount, money_amount]
		ConversionType.MONEY_TO_SCORE:
			return "Spend $%d to gain %d score" % [money_amount, score_amount]
	return ""

func get_keywords() -> Array[StringName]:
	match conversion_type:
		ConversionType.SCORE_TO_MONEY:
			return [Keywords.INCOME, Keywords.COST]
		ConversionType.MONEY_TO_SCORE:
			return [Keywords.COST, Keywords.SCORE]
	return []
