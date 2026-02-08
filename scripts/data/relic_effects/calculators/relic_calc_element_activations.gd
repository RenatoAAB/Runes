class_name RelicCalcElementActivations
extends RelicMultiplierCalculator

## Elementais (Rochedo / Inferno / Céu / Oceano)
## ×(1 + Y×0.01) onde Y é a quantidade de ativações do elemento configurado.

@export var element: GameEnums.Element = GameEnums.Element.EARTH
@export var percent_per_activation: float = 0.01


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.get_element_activations(element)
	if count <= 0:
		return 1.0
	return 1.0 + (count * percent_per_activation)


func get_description() -> String:
	return "×(1 + Y×%.2f) onde Y é a quantidade de ativações de %s." % [percent_per_activation, _element_name(element)]


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
