class_name PayloadRotateRunes
extends EffectPayload

@export var clockwise: bool = true

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	context.grid.rotate_runes(targets, clockwise)

func get_description() -> String:
	return "Rotates targets %s" % ("Clockwise" if clockwise else "Counter-Clockwise")
