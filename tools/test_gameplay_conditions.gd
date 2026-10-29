extends SceneTree

class NestedConditionalAction extends EffectAction:
	var nested_effect: GameEffect
	var requirement: NewEffectCondition

	func execute(ctx: EffectContext, _targets: Array[GridSlot]) -> void:
		requirement.evaluate_for_execution(ctx)
		nested_effect.execute(ctx)
		requirement.evaluate_for_execution(ctx)

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func make_rune() -> RuneInstance:
	var data := RuneData.new()
	data.base_max_activations = 1
	return RuneInstance.new(data)

func _run() -> void:
	EffectLogger.enabled = false
	var grid := GridManager.new()
	grid._init_grid()
	var battle := BattleContext.new(grid)
	var source := grid.get_slot(Vector2i(2, 2))
	source.rune = make_rune()
	var ctx := EffectContext.new(source.rune, source, battle)
	var requirement := ConditionRemainingActivations.new()
	check(requirement.evaluate(ctx), "Preview sees satisfied requirement")
	check(battle.successful_conditions_count == 0, "Preview does not count")
	check(requirement.evaluate_for_execution(ctx), "Execution sees requirement")
	check(battle.successful_conditions_count == 1, "Execution counts once")
	source.rune.current_activations = 1
	check(not requirement.evaluate_for_execution(ctx), "Unmet requirement fails")
	check(battle.successful_conditions_count == 1, "Failure does not count")
	ConditionAlwaysNew.new().evaluate_for_execution(ctx)
	var composite := ConditionComposite.new()
	composite.evaluate_for_execution(ctx)
	composite.conditions = [ConditionAlwaysNew.new()]
	composite.evaluate_for_execution(ctx)
	check(battle.successful_conditions_count == 1, "Always and empty composites do not count")
	source.rune.current_activations = 0
	composite.conditions = [requirement, requirement]
	composite.evaluate_for_execution(ctx)
	check(battle.successful_conditions_count == 2, "AND requirement counts once")
	composite.mode = ConditionComposite.Mode.OR
	composite.evaluate_for_execution(ctx)
	check(battle.successful_conditions_count == 3, "OR requirement counts once")
	var effect := GameEffect.new()
	effect.selector = SelectorSelf.new()
	effect.action = EffectAction.new()
	effect.execute(ctx)
	check(battle.successful_conditions_count == 3, "Unconditional effect does not count")
	effect.condition = requirement
	effect.execute(ctx)
	check(battle.successful_conditions_count == 4, "Effect records condition only once")
	source.slot.data.id = "slot_refractor"
	source.rune.current_activations = 1
	check(effect.execute(ctx), "Refractor bypass still executes")
	check(battle.successful_conditions_count == 4, "Bypass is not natural success")
	source.slot.data.id = "default"
	battle.reset_round_state()
	check(battle.successful_conditions_count == 0, "Round resets conditions")
	var golem_mana := load("res://resources/effects/rune_effects/ge_s3_consume_residue_adj_perm50.tres") as GameEffect
	var golem_anomaly := load("res://resources/effects/rune_effects/ge_s3_consume_anomaly_adj_perm100.tres") as GameEffect
	check(not golem_mana.execute(ctx), "Golem without residue fails requirement")
	check(battle.successful_conditions_count == 0, "Golem without residue does not count")
	grid.get_slot(Vector2i(2, 1)).slot.apply_residue("mana_residue")
	grid.get_slot(Vector2i(1, 2)).slot.apply_residue("mana_residue")
	grid.get_slot(Vector2i(3, 2)).slot.apply_residue("mana_anomaly")
	check(golem_mana.execute(ctx), "Golem mana effect executes")
	check(golem_anomaly.execute(ctx), "Golem anomaly effect executes")
	check(battle.successful_conditions_count == 2, "Golem counts each rule once, not each consumed residue")
	check(source.rune.permanent_buffs.get("score_bonus", 0) == 200, "Golem keeps per-residue score")
	check(not grid.get_slot(Vector2i(2, 1)).slot.has_specific_residue("mana_residue"), "Golem consumed residue")
	var exhausted := grid.get_slot(Vector2i(2, 0))
	exhausted.rune = make_rune()
	exhausted.rune.current_activations = 1
	var disabled := grid.get_slot(Vector2i(2, 1))
	disabled.rune = make_rune()
	disabled.rune.is_disabled = true
	var charged := grid.get_slot(Vector2i(2, 3))
	charged.rune = make_rune()
	var exhausted_two := grid.get_slot(Vector2i(2, 4))
	exhausted_two.rune = make_rune()
	exhausted_two.rune.current_activations = 1
	var geada := load("res://resources/effects/rune_effects/ge_s3_trigger_or_buff_column.tres") as GameEffect
	check(geada.execute(ctx), "Geada executes")
	check(battle.successful_conditions_count == 3, "Geada counts once for two exhausted targets")
	check(exhausted.rune.get_max_activations() == 2, "Geada refunds exhausted target")
	check(exhausted.rune.current_activations == 1, "Geada does not activate refunded target")
	check(disabled.rune.get_max_activations() == 1, "Disabled target with charges is not exhausted")
	check(charged.rune.current_activations == 1, "Charged target activates normally")
	var no_charges := load("res://resources/effects/shared/conditions/condition_no_remaining_activations.tres") as NewEffectCondition
	geada = geada.duplicate() as GameEffect
	geada.condition = no_charges
	exhausted.rune.current_activations = exhausted.rune.get_max_activations()
	exhausted_two.rune.current_activations = exhausted_two.rune.get_max_activations()
	check(geada.execute(ctx), "Geada executes again with outer and target requirements")
	check(battle.successful_conditions_count == 4, "New execution counts once despite outer and multiple target requirements")
	var stats := BattleRoundStatistics.build_from(battle, grid)
	var alchemist := RelicCalcPerSuccessfulCondition.new()
	check(is_equal_approx(alchemist.calculate_multiplier(stats), pow(1.05, 4)), "Alchemist consumes modeled condition total")
	var nested_action := NestedConditionalAction.new()
	nested_action.requirement = no_charges
	nested_action.nested_effect = GameEffect.new()
	nested_action.nested_effect.condition = no_charges
	nested_action.nested_effect.selector = SelectorSelf.new()
	nested_action.nested_effect.action = EffectAction.new()
	var outer := GameEffect.new()
	outer.condition = no_charges
	outer.selector = SelectorSelf.new()
	outer.action = nested_action
	check(outer.execute(ctx), "Nested effect reuses context")
	check(battle.successful_conditions_count == 6, "Parent and nested effect count once each, restoring parent scope")
	outer.execute(ctx)
	check(battle.successful_conditions_count == 8, "Repeated nested execution starts fresh scopes")
	grid.free()
	print("GAMEPLAY CONDITIONS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
