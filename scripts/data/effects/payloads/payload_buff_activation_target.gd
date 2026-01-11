class_name PayloadBuffActivationTarget
extends EffectPayload

## Adds activation charges to target runes.
## Can be used for: Gota (+2 to next), Agua (+1 to adjacents), Rio (+1 to row/column).

@export var activation_bonus: int = 1
@export var is_permanent: bool = false  ## If true, adds to permanent buffs

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var buffed_count = 0
	
	for slot in targets:
		if slot.is_empty():
			continue
		
		var target_rune = slot.rune
		
		if is_permanent:
			var current = target_rune.permanent_buffs.get("activation_bonus", 0)
			target_rune.permanent_buffs["activation_bonus"] = current + activation_bonus
		else:
			var current = target_rune.stat_modifiers.get("activation_bonus", 0)
			target_rune.stat_modifiers["activation_bonus"] = current + activation_bonus
		
		buffed_count += 1
		print("Buffed %s with +%d activations" % [target_rune.data.rune_name, activation_bonus])
	
	if buffed_count > 0:
		print("%s: Buffed %d runes with +%d activations each" % [source_rune.data.rune_name, buffed_count, activation_bonus])


func get_description() -> String:
	var perm_str = " permanent" if is_permanent else ""
	return "+%d%s Activation(s) to targets" % [activation_bonus, perm_str]


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.BUFF, Keywords.CHARGED]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
