class_name PayloadScorePerRemainingActivations
extends EffectPayload

## Adds score based on remaining activations of source or target runes.
## Used for: Gelo (+10 per own remaining), Óleo (+10 per fire adjacent remaining), Som (reader steps)

enum ActivationSource {
	SELF,           ## Count remaining activations of source rune
	TARGETS,        ## Count remaining activations of all target runes
	TARGETS_SUM     ## Sum of all remaining activations from targets
}

@export var score_per_activation: int = 10
@export var activation_source: ActivationSource = ActivationSource.SELF
@export var is_permanent: bool = false

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	var activation_count = 0
	
	match activation_source:
		ActivationSource.SELF:
			activation_count = source_rune.get_max_activations() - source_rune.current_activations
		
		ActivationSource.TARGETS:
			for slot in targets:
				if slot.is_empty():
					continue
				var target_rune = slot.rune
				var remaining = target_rune.get_max_activations() - target_rune.current_activations
				if remaining > 0:
					activation_count += 1  # Count runes with remaining activations
		
		ActivationSource.TARGETS_SUM:
			for slot in targets:
				if slot.is_empty():
					continue
				var target_rune = slot.rune
				var remaining = target_rune.get_max_activations() - target_rune.current_activations
				activation_count += remaining
	
	if activation_count <= 0:
		return
	
	var total = activation_count * score_per_activation
	apply_score(total, source_rune, context, is_permanent)


func get_description() -> String:
	var source_str = ""
	match activation_source:
		ActivationSource.SELF:
			source_str = "own remaining activation"
		ActivationSource.TARGETS:
			source_str = "target with remaining activations"
		ActivationSource.TARGETS_SUM:
			source_str = "remaining activation in targets"
	
	var perm_str = " permanent" if is_permanent else ""
	return "+%d%s Score per %s" % [score_per_activation, perm_str, source_str]


func get_keywords() -> Array[StringName]:
	var kw: Array[StringName] = [Keywords.SCORE, Keywords.CHARGED]
	if is_permanent:
		kw.append(Keywords.PERMANENT)
	return kw
