class_name ActionRefundActivation
extends EffectAction

## Retroactively refunds the current activation charge by decrementing current_activations.
## Used by Eletricidade: "Se ativada simultaneamente, não gasta ativação"
##
## NOTE: This is intentionally different from ActionFreeActivation.
## ActionFreeActivation sets next_activation_free = true, which affects the NEXT activation.
## This action undoes the charge already consumed during the current on_activate() call.


func execute(ctx: EffectContext, targets: Array[GridSlot]) -> void:
	EffectLogger.log_action(ctx, self, targets)
	if not ctx:
		return

	for slot in targets:
		if slot.is_empty():
			continue
		if slot.rune.current_activations > 0:
			slot.rune.current_activations -= 1


func get_description() -> String:
	return "Refunds the current activation charge"


func get_keywords() -> Array[StringName]:
	return [Keywords.BUFF, Keywords.CHARGED]
