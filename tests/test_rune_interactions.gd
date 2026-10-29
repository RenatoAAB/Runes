extends SceneTree
## Regression tests use real mouse gestures, production scene and production overlays.
var checks := 0
var failures := 0
var cases: Array[Dictionary] = []
var main: Node
var viewport: SubViewport
var pointer := Vector2.ZERO
var capture := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	cases.append({"passed":ok,"case":label})
	if not ok:
		failures += 1
		push_error(label)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func move_mouse(point: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = point
	viewport.push_input(event, true)
	await settle()

func button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pointer
	event.global_position = pointer
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	viewport.push_input(event, true)
	await settle()

func center(control: Control) -> Vector2:
	return control.get_global_transform() * (control.size * 0.5)

func grab(ui: RuneUI) -> void:
	await move_mouse(center(ui))
	await button(true)
	await move_mouse(pointer + Vector2(18, 0), true)
	check(viewport.gui_is_dragging(), "Mouse gesture starts rune drag")

func snap(label: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://tests/" + label + ".png")

func drop_state(slot: SlotUI) -> int:
	# Missing feedback is a regression, not a script error on the unfixed version.
	return slot.multi_effect_overlay.get_drop_state() if slot.multi_effect_overlay.has_method("get_drop_state") else -1

func make_rune() -> RuneInstance:
	var data: RuneData = load("res://resources/runes/common/rune_gota.tres").duplicate()
	var effect := GameEffect.new()
	effect.selector = SelectorAdjacent.new()
	effect.action = EffectAction.new()
	data.effects.assign([effect])
	return RuneInstance.new(data)

func run() -> void:
	if not OS.get_user_data_dir().contains("runes-victory-tests"):
		push_error("Use tools/run_tests.py to isolate saves")
		quit(1)
		return
	capture = "--capture" in OS.get_cmdline_user_args()
	EffectLogger.enabled = false
	main = load("res://scenes/main.tscn").instantiate()
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(main)
	current_scene = viewport
	await settle()
	main._on_view_panel_requested()
	await settle()
	var source: SlotUI = main.grid_ui_slots[Vector2i(0,0)]
	var target: SlotUI = main.grid_ui_slots[Vector2i(1,0)]
	var locked: SlotUI = main.grid_ui_slots[Vector2i(4,4)]
	# Deterministic board using the actual model, without replacing UI handlers.
	for coord in main.grid_ui_slots:
		main.grid_manager.get_slot(coord).remove_rune()
		main._on_grid_slot_changed(coord)
	# Exercise existing hover/drag/rejection/cancel routes with authored borders active.
	for entry in [[Vector2i(0,0), "accumulator"], [Vector2i(1,0), "conector"]]:
		var modifier: SlotModifierData = load("res://resources/slot_modifiers/slot_" + entry[1] + ".tres")
		main.grid_manager.get_slot(entry[0]).slot.apply_modifier(modifier)
		main._on_grid_slot_changed(entry[0])
	var rune := make_rune()
	main.grid_manager.place_rune_instance(rune, Vector2i(0,0))
	await settle()
	var ui: RuneUI = source.rune_ui
	var highlighter: GridHighlighter = main.grid_highlighter
	await move_mouse(center(ui))
	check(highlighter.get_effects_at_position(Vector2i(1,0)) == [0], "Hover computes adjacent effect target")
	check(target.multi_effect_overlay.get_effect_indices() == [0], "Hover reaches visible board overlay")
	await snap("hover-effects")
	await move_mouse(Vector2(620,15))
	check(not target.multi_effect_overlay.has_effects(), "Leaving rune clears hover effects")
	await grab(ui)
	var offset := pointer - ui.global_position
	await move_mouse(center(target), true)
	check(ui.global_position.is_equal_approx(pointer-offset), "Actual rune follows pointer without a ghost")
	check(drop_state(target) == 1, "Valid empty board destination is green during drag")
	check(target.multi_effect_overlay.get_effect_indices() == [0], "Dragging keeps the carried rune's effects visible at its current board origin")
	await snap("valid-drop")
	await move_mouse(center(locked), true)
	check(drop_state(target) == -1, "Previous destination clears when pointer moves")
	check(drop_state(locked) == 0, "Locked board destination is red during drag")
	check(target.multi_effect_overlay.get_effect_indices() == [0], "Leaving a drop target does not erase the carried rune's effect highlights")
	await snap("invalid-drop")
	await button(false)
	check(source.rune_ui == ui and not ui.is_dragging_rune(), "Invalid drop restores original rune")
	check(drop_state(locked) == -1, "Cancel clears destination feedback")
	await move_mouse(center(ui))
	check(target.multi_effect_overlay.get_effect_indices() == [0], "Hover effects recover after cancelled drag")
	await grab(ui)
	await move_mouse(center(target), true)
	await button(false)
	check(target.rune_ui != null and target.rune_ui.rune_instance == rune and source.rune_ui == null, "Board drop moves the same rune instance")
	await move_mouse(Vector2(620,15))
	await move_mouse(center(target.rune_ui))
	check(source.multi_effect_overlay.get_effect_indices() == [0], "Hover recomputes effects from the new origin after drop")
	check(drop_state(target) == -1, "Successful drop clears destination feedback")
	# Inventory source: occupied board destination must be red (no implicit replacement).
	var inventory: SlotUI = main.inventory_container.get_child(0)
	var inventory_rune := inventory.rune_ui.rune_instance
	await grab(inventory.rune_ui)
	await move_mouse(center(target), true)
	check(drop_state(target) == 0, "Inventory to occupied board target is invalid")
	await button(false)
	check(main.inventory_manager.has_rune(inventory_rune) and target.rune_ui.rune_instance == rune, "Rejected occupied target preserves both runes")
	# Same-slot cancellation must still allow hover without requiring a second entry.
	await grab(target.rune_ui)
	await move_mouse(center(target), true)
	await button(false)
	check(source.multi_effect_overlay.get_effect_indices() == [0], "Hover highlight is restored beneath pointer immediately after drag ends")
	# Tooltips clamped over a board cell must never steal its hover or drop input.
	var tooltip: TooltipManager = get_first_node_in_group("tooltip_manager")
	tooltip.set_process(false)
	tooltip.set_rune_tooltip("A tooltip overlapping the hovered rune")
	tooltip.panel.global_position = target.global_position
	await settle()
	await move_mouse(center(target) + Vector2(1,1))
	check(viewport.gui_get_hovered_control() == target.rune_ui, "Tooltip text cannot intercept board input even when overlapping")
	check(source.multi_effect_overlay.get_effect_indices() == [0], "Overlapping tooltip does not erase effect highlights")
	tooltip.set_process(true)
	# Gameplay restrictions remain intact.
	var board_rune: RuneUI = target.rune_ui
	main.grid_manager.get_slot(Vector2i(1,0)).add_state("petrified",2)
	check(board_rune._get_drag_data(Vector2.ZERO) == null, "Petrified source cannot be dragged")
	main.grid_manager.get_slot(Vector2i(1,0)).remove_state("petrified")
	var phase: int = main.game_manager.current_phase
	for blocked_phase in [GameEnums.GamePhase.BATTLE, GameEnums.GamePhase.RESOLUTION]:
		main.game_manager.current_phase = blocked_phase
		check(board_rune._get_drag_data(Vector2.ZERO) == null, "Phase %d blocks dragging" % blocked_phase)
	main.game_manager.current_phase = phase
	await check_relic_presentation()
	for relic_key in ["alchemist", "squire", "destroyer", "creator", "engineer", "anomalous", "boulder", "bulwark", "child", "inferno", "ocean", "sky", "ether", "void", "return", "collector", "conductor", "clown"]:
		await check_relic_art(relic_key)
	var file := FileAccess.open("res://tests/ui-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(cases,"\t"))
	print("RUNE INTERACTIONS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func set_money(amount: int) -> void:
	var event := EconomyEvent.new()
	event.transaction_type = EconomyEvent.TransactionType.ROUND_BONUS
	event.amount = amount - root.get_node("Stats").get_money()
	event.balance_before = root.get_node("Stats").get_money()
	event.balance_after = amount
	event.source = "relic_art_test"
	root.get_node("EventBus").emit(event)

func click_control(control: Control) -> void:
	await move_mouse(center(control))
	await button(true)
	await button(false)

func relic_inventory_slot(relic: RelicInstance) -> SlotUI:
	for slot: SlotUI in main.inventory_ui_slots:
		if slot.item_ui and slot.item_ui.item_instance == relic:
			return slot
	return null

func check_relic_art(relic_key: String) -> void:
	var data: RelicData = load("res://resources/relics/relic_%s.tres" % relic_key)
	check(data.icon is AnimatedTexture, "%s uses its approved animated icon" % relic_key)
	if not data.icon is AnimatedTexture:
		return
	var animation := data.icon as AnimatedTexture
	check(animation.get_size() == Vector2(32,32) and animation.frames == 12 and not animation.one_shot, "Relic keeps native32px and twelve looping frames")
	for i in animation.frames:
		check(is_equal_approx(animation.get_frame_duration(i),0.2), "Authored frame%d lasts200ms" % i)
	main._extra_inventory.clear_all()
	main._update_other_inventory_display()
	main._on_enter_shop_pressed()
	await settle()
	var shop: ShopUI = main.shop_ui
	var manager: ShopManager = main.get_shop_manager()
	manager.available_relics.assign([data])
	shop._refresh_relic_shop()
	# Repeated refresh can rename the new child until queued old icons are freed.
	shop._refresh_relic_shop()
	await settle()
	var offer: SlotUI = shop.purchasable_relics_container.get_child(0)
	var icon: TextureRect = offer._display_icon
	check(is_instance_valid(icon) and not icon.is_queued_for_deletion() and icon.get_parent() == offer and icon.texture == animation and icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Shop exposes current approved art without intercepting purchase input")
	var presentation: Node2D = shop.get_node("RelicPresentation")
	check(presentation.states.size() == 1 and presentation.states[0].draw.texture == animation and icon.self_modulate.a == 0 and not offer.get_node("Sprite2D").visible, "All approved relics use one native visual and glow without solid backdrop")
	if icon:
		check(icon.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED and icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Shop draws native pixels with nearest filtering")
	set_money(0)
	await click_control(offer)
	check(manager.available_relics == [data] and main._extra_inventory.relics.is_empty() and root.get_node("Stats").get_money() == 0, "Insufficient mana preserves relic offer and inventory")
	await move_mouse(Vector2(620,15))
	await snap("%s-shop" % relic_key)
	# Rendered playback is sampled over a full cycle; headless renderer has no texture clock.
	if capture:
		var observed := {}
		for i in 28:
			await create_timer(0.1).timeout
			observed[animation.current_frame] = true
			await snap("%s-loop-%02d" % [relic_key, i])
		check(observed.size() == 12, "Rendered production shop plays all twelve authored frames")
	set_money(100)
	var cost := ShopConfig.get_relic_buy_price(data)
	await move_mouse(presentation.states[0].visual.global_position)
	await button(true)
	await button(false)
	check(manager.available_relics.is_empty() and main._extra_inventory.relics.size() == 1 and root.get_node("Stats").get_money() == 100-cost, "Clicking animated offer buys one relic at unchanged price")
	check(not offer.visible and offer._display_icon == null, "Purchased offer removes animated icon")
	if main._extra_inventory.relics.is_empty():
		return
	var relic: RelicInstance = main._extra_inventory.relics[0]
	var inventory := relic_inventory_slot(relic)
	check(inventory != null and inventory.item_ui.texture == animation, "Purchased relic keeps animation in inventory")
	if inventory == null:
		return
	check(inventory.item_ui._background.color.a == 0.0 and inventory.item_ui.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED, "Inventory reveals native icon without opaque placeholder fill")
	main._on_view_panel_requested()
	await settle()
	await snap("%s-inventory" % relic_key)
	var target: SlotUI = main._relic_slot_uis[0]
	await move_mouse(center(inventory.item_ui))
	await button(true)
	await move_mouse(pointer + Vector2(18,0),true)
	check(viewport.gui_is_dragging(), "Native relic icon retains inventory drag gesture")
	await move_mouse(center(target),true)
	await button(false)
	check(target._relic_instance == relic and relic.is_attached() and not main._extra_inventory.relics.has(relic), "Drag equips the same relic instance")
	check(target.item_ui != null and target.item_ui.texture == animation, "Equipped relic retains approved loop")
	await move_mouse(Vector2(620,15))
	await snap("%s-equipped" % relic_key)
	# Removal visual lifecycle uses the existing action. Equipped ItemUI owns clicks;
	# this check does not claim an end-to-end click-removal gesture.
	main._on_relic_clicked(relic)
	await settle()
	check(not relic.is_attached() and main._extra_inventory.relics.has(relic) and target.item_ui == null, "Existing removal action returns relic and clears its animated visual")
	manager.available_relics.assign([data])
	shop._refresh_relic_shop()
	await settle()
	# Local fixture keeps fallback coverage independent of future relic art.
	var unillustrated := data.duplicate() as RelicData
	unillustrated.icon = null
	manager.available_relics.assign([unillustrated])
	shop._refresh_relic_shop()
	await settle()
	check(offer._display_icon == null and offer._placeholder_label.visible, "Replacing animated offer with unillustrated relic restores placeholder")
	manager.available_relics.clear()
	shop._refresh_relic_shop()
	await settle()
	check(not offer.visible and not offer._placeholder_label.visible, "Empty offer clears all relic presentation")

func click_relic_seal() -> void:
	var seal: Button = main.shop_ui.relic_seal_button
	# Hit a real opaque pedestal/crystal pixel, not the transparent button bounds.
	for y in int(seal.size.y):
		for x in int(seal.size.x):
			if seal._has_point(Vector2(x,y)):
				await move_mouse(seal.global_position + Vector2(x,y))
				await button(true)
				await button(false)
				return
	check(false, "Altar exposes an opaque seal input point")

func check_relic_presentation() -> void:
	main._on_enter_shop_pressed()
	await settle()
	var shop: ShopUI = main.shop_ui
	var manager: ShopManager = main.get_shop_manager()
	var presentation: Node2D = shop.get_node_or_null("RelicPresentation")
	check(presentation != null, "Shop composes relic presentation without replacing input controls")
	if presentation == null: return
	check(presentation.base_visual_offset == Vector2(0, -4) and presentation.glow_color == Color.WHITE, "Relic presentation uses raised base and white glow")
	manager.reset_relic_seal()
	main._extra_inventory.clear_all()
	main._update_other_inventory_display()
	var data: RelicData = load("res://resources/relics/relic_clown.tres")
	manager.available_relics.assign([data])
	shop._refresh_relic_shop()
	shop._refresh_relic_shop()
	await settle()
	var offer: SlotUI = shop.purchasable_relics_container.get_child(0)
	var fixed_rect := offer.get_global_rect()
	check(presentation.states.size() == 1 and presentation.states[0].icon == offer._display_icon, "Repeated same-frame refresh leaves exactly one current visual")
	var state: Dictionary = presentation.states[0]
	check(offer._display_icon.self_modulate.a == 0 and not offer.get_node("Sprite2D").visible, "Composed offer removes original icon and solid backdrop only")
	check(state.draw.texture == data.icon and state.draw.mouse_filter == Control.MOUSE_FILTER_IGNORE and state.draw.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Visual copy shares authored texture and cannot intercept input")
	await move_mouse(state.visual.global_position)
	var tooltip: TooltipManager = get_first_node_in_group("tooltip_manager")
	check(state.hovered and state.outline.get_shader_parameter("show_outline"), "Real offer hover shows proxy outline")
	check(tooltip.panel.visible and tooltip.label.text.contains(data.display_name) and tooltip.label.text.contains("10"), "Real offer hover preserves relic identity and price tooltip")
	await snap("presentation-hover")
	await move_mouse(Vector2(620,15))
	check(not state.hovered and not state.outline.get_shader_parameter("show_outline"), "Leaving offer clears visual hover")
	var positions := {}
	for i in 22:
		await create_timer(0.1).timeout
		positions[state.visual.position.y] = true
	check(positions.size() >= 3 and offer.get_global_rect() == fixed_rect, "Open relic floats while its purchase hitbox remains fixed")
	await snap("presentation-open")
	set_money(0)
	await settle()
	await click_relic_seal()
	check(not manager.relic_sealed and root.get_node("Stats").get_money() == 0 and manager.available_relics == [data], "Insufficient mana rejects actual seal click without state or offer changes")
	set_money(100)
	await settle()
	await click_relic_seal()
	check(manager.relic_sealed and root.get_node("Stats").get_money() == 99 and manager.available_relics == [data], "Actual seal click costs exactly one mana and keeps the offer")
	await move_mouse(Vector2(620,15))
	state = presentation.states[0]
	var locked_position: Vector2 = state.visual.position
	var expected_center: Vector2 = presentation.to_local(offer._display_icon.get_global_rect().get_center()) + Vector2(0, -4)
	var stable := true
	var energy_frames := {}
	var binding_levels := {}
	var pulse_synced := true
	for i in 12:
		await create_timer(0.1).timeout
		stable = stable and state.visual.position == locked_position
		energy_frames[(data.icon as AnimatedTexture).current_frame] = true
		if capture:
			await RenderingServer.frame_post_draw
			var circle_color: Color = shop.relic_seal_button.sealed_circle.modulate
			pulse_synced = pulse_synced and is_equal_approx(presentation.binding_intensity, circle_color.get_luminance() * circle_color.a)
			binding_levels[snappedf(presentation.binding_intensity, 0.001)] = true
	check(stable and locked_position == expected_center and offer.get_global_rect() == fixed_rect, "Seal fixes relic center and hitbox with zero spatial motion")
	check(not capture or (pulse_synced and binding_levels.size() == 2), "Rendered bindings follow both live circle intensity phases without drift")
	check(not (data.icon as AnimatedTexture).pause and (not capture or energy_frames.size() > 1), "Seal preserves shared authored energy animation")
	var anchors: PackedVector2Array = presentation.circle_anchors()
	check(anchors.size() == 3, "Three binding endpoints follow the authored circle")
	var circle: Sprite2D = shop.relic_seal_button.sealed_circle
	var mask := circle.texture.get_image()
	var on_circle := true
	for point in anchors:
		var pixel := Vector2i(circle.to_local(presentation.to_global(point)))
		on_circle = on_circle and mask.get_pixelv(pixel).a > 0.1
	check(on_circle, "All bindings terminate on opaque pixels of the real magic circle")
	await snap("presentation-locked")
	var balance_before_reroll: int = root.get_node("Stats").get_money()
	await click_control(shop.get_node("ElementPedestals/Repeat"))
	check(root.get_node("Stats").get_money() == balance_before_reroll - 1 and manager.relic_sealed and manager.available_relics == [data] and presentation.states[0].draw.texture == data.icon, "Real neutral pedestal reroll preserves the sealed relic and its visual")
	shop.hide()
	await settle()
	check(presentation.states.is_empty(), "Hiding sealed shop removes all binding geometry and glow")
	shop.show()
	await settle()
	check(presentation.states.size() == 1 and presentation.states[0].visual.position == locked_position, "Reopening sealed shop restores one stationary relic")
	set_money(0)
	await settle()
	await click_relic_seal()
	await click_control(offer)
	check(manager.relic_sealed and manager.available_relics == [data] and main._extra_inventory.relics.is_empty() and root.get_node("Stats").get_money() == 0, "Insufficient mana rejects unseal and locked purchase with no state loss")
	set_money(100)
	await settle()
	await click_relic_seal()
	check(not manager.relic_sealed and root.get_node("Stats").get_money() == 99 and manager.available_relics == [data], "Actual release click costs exactly one mana and keeps the offer")
	await move_mouse(Vector2(620,15))
	positions.clear()
	for i in 12:
		await create_timer(0.1).timeout
		positions[presentation.states[0].visual.position.y] = true
	check(positions.size() > 1, "Released relic resumes spatial motion")
	await snap("presentation-released")
	await click_relic_seal()
	set_money(100)
	await settle()
	await move_mouse(presentation.states[0].visual.global_position)
	await button(true)
	await button(false)
	check(manager.relic_sealed and manager.available_relics.is_empty() and main._extra_inventory.relics.size() == 1 and root.get_node("Stats").get_money() == 90, "Actual locked purchase charges ten once and preserves seal")
	check(presentation.states.is_empty() and shop.relic_seal_button.red_circle.visible, "Locked purchase clears visual effects and reveals the empty red circle")
	await move_mouse(Vector2(620,15))
	await snap("presentation-empty-sealed")
	manager.refresh_shop(manager.current_level)
	await settle()
	check(manager.relic_sealed and manager.available_relics.is_empty() and presentation.states.is_empty() and shop.relic_seal_button.red_circle.visible, "Next round preserves empty sealed altar without stale effects")
	await click_relic_seal()
	check(not manager.relic_sealed and manager.available_relics.is_empty() and root.get_node("Stats").get_money() == 89, "Empty altar release costs one and creates no immediate offer")
	manager.refresh_shop(manager.current_level)
	await settle()
	check(manager.available_relics.size() == 1 and presentation.states.size() == 1 and not shop.relic_seal_button.red_circle.visible, "Following round restocks released altar with one fresh visual")
	for key in ["boulder", "void", "return", "clown"]:
		var replacement: RelicData = load("res://resources/relics/relic_%s.tres" % key)
		manager.available_relics.assign([replacement])
		shop._refresh_relic_shop()
		shop._refresh_relic_shop()
		await settle()
		check(presentation.states.size() == 1 and presentation.states[0].draw.texture == replacement.icon, "Replacement %s leaves one current visual" % key)
		await move_mouse(Vector2(620,15))
		await snap("presentation-%s-open" % key)
		await click_relic_seal()
		await move_mouse(Vector2(620,15))
		await snap("presentation-%s-locked" % key)
		manager.refresh_shop(manager.current_level)
		await settle()
		check(manager.relic_sealed and manager.available_relics == [replacement] and presentation.states[0].draw.texture == replacement.icon, "Round refresh preserves sealed %s offer and visual" % key)
		await click_relic_seal()
	var icon: TextureRect = offer._display_icon
	shop.hide()
	await settle()
	check(presentation.states.is_empty() and icon.self_modulate.a == 1 and offer.get_node("Sprite2D").visible, "Hiding shop clears effects and restores source presentation")
	shop.show()
	await settle()
	check(presentation.states.size() == 1 and presentation.states[0].icon == icon and icon.self_modulate.a == 0, "Reopening shop composes exactly one current icon")
	presentation.presentation_enabled = false
	await settle()
	check(presentation.states.is_empty() and icon.self_modulate.a == 1 and offer.get_node("Sprite2D").visible, "Disabled presentation restores original icon and backdrop")
	presentation.presentation_enabled = true
	await settle()
	var fallback := data.duplicate() as RelicData
	fallback.icon = null
	manager.available_relics.assign([fallback])
	shop._refresh_relic_shop()
	await settle()
	check(presentation.states.is_empty() and offer._placeholder_label.visible and offer.get_node("Sprite2D").visible, "Unillustrated fallback restores its normal placeholder and backdrop")
	manager.available_relics.clear()
	shop._refresh_relic_shop()
	await settle()
	check(presentation.states.is_empty() and not offer.visible, "Empty unsealed offer has no glow or bindings")
	main._extra_inventory.clear_all()
	main._update_other_inventory_display()

