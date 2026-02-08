class_name RelicCalcElementRowColumn
extends RelicMultiplierCalculator

## A Criança
## ×1.1 por cada linha ou coluna inteira do elemento configurado.

@export var element: GameEnums.Element = GameEnums.Element.EARTH
@export var per_line_multiplier: float = 1.1


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.get_element_lines(element)
	if count <= 0:
		return 1.0
	return pow(per_line_multiplier, count)


func get_description() -> String:
	return "×%.1f por cada linha ou coluna inteira de %s." % [per_line_multiplier, _element_name(element)]


func _element_name(elem: GameEnums.Element) -> String:
	match elem:
		GameEnums.Element.FIRE:
			return "Fogo"
		GameEnums.Element.WATER:
			return "Água"
		GameEnums.Element.EARTH:
			return "Terra"
		GameEnums.Element.AIR:
			return "Ar"
		GameEnums.Element.SPIRIT:
			return "Espírito"
		_:
			return "Elemento"
