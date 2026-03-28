class_name ActionFreeActivation
extends EffectAction

## Marks target runes so their next activation does not consume a charge.
## Used by Tempo: "A próxima ativação da runa inferior não gasta ativação"
## Used by Eletricidade: "Se ativada simultaneamente, não gasta ativação"


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		slot.rune.next_activation_free = true


func get_description() -> String:
	return "Next activation doesn't spend a charge"


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.CHARGED]
