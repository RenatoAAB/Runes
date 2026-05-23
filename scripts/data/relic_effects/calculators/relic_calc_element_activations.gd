class_name RelicCalcElementActivations
extends RelicMultiplierCalculator

## Elementais (Rochedo / Inferno / Céu / Oceano)
## ×M^Y onde Y é a quantidade de ativações do elemento configurado.

@export var element: GameEnums.Element = GameEnums.Element.EARTH
@export var per_activation_multiplier: float = 1.05


func calculate_multiplier(stats: BattleRoundStatistics) -> float:
	var count := stats.get_element_activations(element)
	if count <= 0:
		return 1.0
	return pow(per_activation_multiplier, count)


func get_description() -> String:
	return "×%.2f por cada ativação de %s na rodada." % [per_activation_multiplier, _element_name(element)]


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
