class_name PayloadConsumeActivation
extends EffectPayload

## Consumes activations from target runes and adds score for each success.

@export var score_per_success: int = 30

var successful_absorptions: int = 0

func execute(targets: Array[GridSlot], source_rune: RuneInstance, context: BattleContext) -> void:
	successful_absorptions = 0
	
	for slot in targets:
		if slot.is_empty():
			continue
		var target_rune = slot.rune
		if target_rune == source_rune:
			continue
		
		# Check if target has activations remaining
		if target_rune.current_activations < target_rune.get_max_activations():
			# Consume one activation by increasing current_activations
			target_rune.current_activations += 1
			successful_absorptions += 1
			print("Consumed activation from %s" % target_rune.data.rune_name)
	
	if successful_absorptions > 0:
		var total_score = successful_absorptions * score_per_success
		var final_score = source_rune.get_modified_score(total_score)
		context.add_score(final_score, source_rune)
		print("Gained %d score from %d absorbed activations" % [final_score, successful_absorptions])

func get_description() -> String:
	return "Consumes 1 activation from targets, +%d Score each" % score_per_success
