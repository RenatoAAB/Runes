extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	EffectLogger.enabled = false
	var grid := GridManager.new()
	grid._init_grid()
	var highlighter := GridHighlighter.new()
	highlighter.grid_manager = grid
	root.add_child(highlighter)
	var data := RuneData.new()
	data.base_max_activations = 1
	var effect := GameEffect.new()
	effect.condition = ConditionRemainingActivations.new()
	effect.selector = SelectorAdjacent.new()
	effect.action = EffectAction.new()
	data.effects.assign([effect])
	var rune := RuneInstance.new(data)
	var initial_buffs := rune.permanent_buffs.duplicate(true)
	var origin := grid.get_slot(Vector2i(2,2))
	origin.rune = rune
	highlighter.highlight_rune_effects(rune, origin)
	for coord in [Vector2i(1,2), Vector2i(3,2), Vector2i(2,1), Vector2i(2,3)]:
		check(highlighter.get_effects_at_position(coord) == [0], "Orthogonal target %s" % coord)
	check(highlighter.get_effects_at_position(Vector2i(1,1)).is_empty(), "Diagonal excluded")
	check(highlighter._preview_context.successful_conditions_count == 0, "Preview never increments gameplay conditions")
	rune.current_activations = 1
	highlighter.highlight_rune_effects(rune, origin)
	check(highlighter.get_effects_at_position(Vector2i(1,2)).is_empty(), "False condition hides effect targets")
	rune.current_activations = 0
	data.effects.append(effect)
	highlighter.highlight_rune_effects(rune, origin)
	check(highlighter.get_effects_at_position(Vector2i(1,2)) == [0,1], "Overlapping effects keep distinct indices")
	highlighter.clear_highlights()
	check(highlighter.get_effects_at_position(Vector2i(1,2)).is_empty(), "Clear removes all target indices")
	highlighter.highlight_rune_effects(null, origin)
	check(highlighter._slot_effect_indices.is_empty(), "Null rune is safe")
	var elemental := ConditionElementAdjacentNew.new()
	elemental.required_elements.assign([GameEnums.Element.FIRE])
	elemental.min_count = 2
	effect.condition = elemental
	data.effects.assign([effect])
	var neighbor_data := RuneData.new()
	neighbor_data.elements.assign([GameEnums.Element.FIRE])
	var neighbor := RuneInstance.new(neighbor_data)
	grid.get_slot(Vector2i(1,2)).rune = neighbor
	highlighter.highlight_rune_effects(rune, origin)
	check(highlighter.has_condition_at_position(Vector2i(1,2)), "Condition border shows matching neighbor even below threshold")
	check(highlighter.get_effects_at_position(Vector2i(1,2)).is_empty(), "Unmet threshold gates target fill independently of condition border")
	elemental.min_count = 1
	# Load after autoloads are initialized; ActionScore references EventBus.
	var score = load("res://scripts/effects/actions/action_score.gd").new()
	score.value = ValueResolver.new()
	var per := ValuePer.new()
	per.source = ValuePer.CountSource.ADJACENT
	score.value.per.assign([per])
	effect.action = score
	highlighter.highlight_rune_effects(rune, origin)
	check(highlighter.has_condition_at_position(Vector2i(1,2)) and highlighter.get_effects_at_position(Vector2i(1,2)) == [0], "Condition and target coexist when satisfied")
	check(highlighter.get_value_sources_at_position(Vector2i(1,2)) == [0], "Value source retains its separate dashed-border index")
	check(origin.rune == rune and grid.get_slot(Vector2i(1,2)).rune == neighbor, "Preview does not move or replace board runes")
	check(rune.current_activations == 0 and rune.permanent_buffs == initial_buffs, "Preview does not consume charges or apply buffs")
	check(highlighter._preview_context.successful_conditions_count == 0, "Repeated previews never change gameplay condition counts")
	highlighter.clear_highlights()
	check(not highlighter.has_condition_at_position(Vector2i(1,2)) and highlighter.get_value_sources_at_position(Vector2i(1,2)).is_empty(), "Clear removes condition and value-source feedback too")
	highlighter.queue_free()
	grid.free()
	await process_frame
	print("HIGHLIGHT RULES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
