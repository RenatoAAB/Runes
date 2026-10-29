extends "res://tests/test_rune_interactions.gd"
## Approved border assets in real production UI and real pointer/drop routes.

func modifier(key: String) -> SlotModifierData:
	return load("res://resources/slot_modifiers/slot_" + key + ".tres")

func check_native_geometry(cell: SlotUI, key: String) -> void:
	var expected_size := 40
	var image := cell._modifier_overlay.texture.get_image()
	check(image.get_size() == Vector2i(expected_size,expected_size), key + " retains approved per-type dimensions")
	if expected_size == 40:
		var alpha_bounds := image.get_used_rect()
		var origin := cell._modifier_overlay.position - Vector2(image.get_size())*0.5
		var physical_bounds := Rect2(origin + Vector2(alpha_bounds.position), Vector2(alpha_bounds.size))
		check(Rect2(Vector2.ZERO,Vector2(40,40)).encloses(physical_bounds), key + " visible border stays inside40px cell")
		check(origin == Vector2.ZERO, key + " native40 overlay has origin0,0")

func inventory_item(data: SlotModifierData) -> ItemUI:
	for cell in main.inventory_ui_slots:
		if cell.item_ui and cell.item_ui.item_data == data:
			return cell.item_ui
	return null

func drag_modifier(ui: ItemUI, destination: Control) -> void:
	await move_mouse(center(ui))
	await button(true)
	await move_mouse(pointer + Vector2(16, 0), true)
	check(viewport.gui_is_dragging(), "Real pointer starts modifier drag")
	await move_mouse(center(destination), true)
	await button(false)

func run() -> void:
	if not OS.get_user_data_dir().contains("runes-victory-tests"):
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
	var keys := ["accumulator", "conector", "stabilizer", "charger", "condenser", "resonator", "igniter", "pressurizer", "refractor"]
	for coord in main.grid_ui_slots:
		main.grid_manager.get_slot(coord).remove_rune()
		main._on_grid_slot_changed(coord)
	for y in 3:
		for x in 3:
			var coord := Vector2i(x,y)
			var data := modifier(keys[(x+y*3)%keys.size()])
			var model: GridSlot = main.grid_manager.get_slot(coord)
			check(model.slot.apply_modifier(data), "Approved modifier applies")
			main._on_grid_slot_changed(coord)
			var cell: SlotUI = main.grid_ui_slots[coord]
			check(cell.size == Vector2(40,40), "Border preserves 40px cell")
			check(cell._modifier_overlay.texture == data.slot_data_override.modifier_overlay_texture, "Panel uses approved border resource")
			check(not cell.clip_contents and cell._modifier_overlay.position == Vector2(20,20), "Native border centered and unclipped")
			check(cell._slot_sprite.texture.get_size() == Vector2(40,40), "Opaque base stays 40px beneath neighbor details")
			check_native_geometry(cell, keys[(x+y*3)%keys.size()])
	await settle()
	await snap("modifiers-empty-grid")
	for coord in [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)]:
		var rune := RuneInstance.new(load("res://resources/runes/common/rune_rocha.tres"))
		main.grid_manager.place_rune_instance(rune, coord)
	await settle()
	await snap("modifiers-occupied-grid")
	# Sample actual native border pixels for all nine approved types.
	if capture:
		await RenderingServer.frame_post_draw
		var frame := viewport.get_texture().get_image()
		for index in keys.size():
			var cell: SlotUI = main.grid_ui_slots[Vector2i(index % 3, index / 3)]
			var overlay := cell._modifier_overlay.texture.get_image()
			var origin := Vector2i(cell.global_position)
			var visible_pixels := 0
			var pixels_exact := true
			for y in overlay.get_height():
				for x in overlay.get_width():
					var pixel := overlay.get_pixel(x,y)
					if pixel.a == 1.0:
						pixels_exact = pixels_exact and frame.get_pixelv(origin + Vector2i(x,y)).is_equal_approx(pixel)
						visible_pixels += 1
			check(pixels_exact and visible_pixels > 0, keys[index] + " rendered native border pixels remain exact beside occupied neighbors")
	await verify_batch04_mounted()
	await verify_batch05_mounted()
	var target: SlotUI = main.grid_ui_slots[Vector2i(1,0)]
	var locked: SlotUI = main.grid_ui_slots[Vector2i(4,4)]
	var first := modifier("accumulator")
	var second := modifier("stabilizer")
	main._extra_inventory.clear_all()
	main._extra_inventory.add_modifier(first)
	await settle()
	var item := inventory_item(first)
	check(item != null and item.has_modifier_icon() and not item.has_modifier_border(), "Inventory displays approved kit without mounted border")
	check(item._background.color == Color.TRANSPARENT and item._label.text == "", "Authored item removes legacy block and abbreviation")
	check(item.size == Vector2(40,40), "Inventory item preserves hitbox")
	await move_mouse(center(item))
	var tooltip: TooltipManager = get_first_node_in_group("tooltip_manager")
	check(tooltip._item_text.contains(first.display_name), "Real hover shows modifier tooltip")
	await snap("modifiers-inventory-hover")
	await move_mouse(center(item))
	await button(true)
	await move_mouse(pointer + Vector2(16,0), true)
	await move_mouse(Vector2(620,15), true)
	await button(false)
	check(main._extra_inventory.modifiers.has(first) and not viewport.gui_is_dragging(), "Cancelled modifier drag preserves item and clears state")
	await drag_modifier(item, locked)
	check(main._extra_inventory.modifiers.has(first), "Rejected locked drop preserves modifier")
	check(not viewport.gui_is_dragging(), "Rejected drop cleans drag state")
	var preserved_rune: RuneInstance = main.grid_manager.get_slot(Vector2i(1,0)).rune
	check(preserved_rune != null, "Accumulator conservation case starts with occupied target")
	await settle()
	item = inventory_item(first)
	await drag_modifier(item, target)
	check(main.grid_manager.get_slot(Vector2i(1,0)).slot.slot_modifier_id == first.id, "Real drop replaces existing modifier")
	check(not main._extra_inventory.modifiers.has(first), "Successful drop consumes one inventory modifier")
	check(target._modifier_overlay.texture == first.slot_data_override.modifier_overlay_texture, "Replacement updates visible border")
	check(main.grid_manager.get_slot(Vector2i(1,0)).rune == preserved_rune, "Accumulator replacement preserves occupied rune instance")
	main._extra_inventory.add_modifier(second)
	await settle()
	await drag_modifier(inventory_item(second), target)
	check(target._modifier_overlay.texture == second.slot_data_override.modifier_overlay_texture, "Second replacement removes previous border")
	# Presentation cleanup leaves no stale border after model removal/context switch.
	var saved: GridSlot = target.current_slot_data
	target.update_slot_info(null)
	check(target._modifier_overlay.texture == null and target.clip_contents, "Empty model clears border and restores clipping")
	target.update_slot_info(saved)
	target.set_locked_state(false)
	check(target._modifier_overlay.texture == null and target.clip_contents, "Locked state hides border")
	target.set_locked_state(true)
	target.update_slot_info(saved)
	for context in [SlotUI.SlotContext.INVENTORY, SlotUI.SlotContext.RELIC, SlotUI.SlotContext.SHOP]:
		target.set_slot_context(context)
		check(target._modifier_overlay.texture == null, "Context switch clears panel decoration")
	target.set_slot_context(SlotUI.SlotContext.PANEL)
	target.update_slot_info(saved)
	main._on_enter_shop_pressed()
	await settle()
	var shop: ShopUI = main.shop_ui
	var manager: ShopManager = main.get_shop_manager()
	manager.available_modifiers.assign([first])
	shop._refresh_modifiers_shop()
	await settle()
	var offer: SlotUI = shop.purchasable_modifiers_container.get_child(0)
	check(offer._modifier_icon != null and offer._modifier_icon.texture == first.icon and offer._modifier_overlay.texture == null, "Shop renders approved kit without mounted border")
	check(offer.size == Vector2(23,19), "Shop preserves existing purchase hitbox")
	check(not offer._slot_sprite.visible and offer._modifier_icon.position == Vector2(11,9), "Shop kit has integer center and no slot background")
	await move_mouse(center(offer))
	await snap("modifiers-shop-hover")
	check(tooltip._rune_text.contains(first.display_name), "Shop hover retains modifier tooltip")
	set_money(0)
	await click_control(offer)
	check(manager.available_modifiers.has(first), "Insufficient mana preserves illustrated offer")
	var extra := second.duplicate() as SlotModifierData
	extra.set_meta("shop_overclock_offer", true)
	manager.overclock_purchased_this_round = true
	manager.available_modifiers.assign([first, extra])
	shop._refresh_modifiers_shop()
	await settle()
	await move_mouse(Vector2(620,15))
	var extra_offer: SlotUI = shop.purchasable_modifiers_container.get_child(1)
	check(extra_offer._modifier_icon.global_position.x - offer._modifier_icon.global_position.x == 34, "Overclock kits remain on natural centers without moving hitboxes")
	check(offer.size == Vector2(23,19) and extra_offer.size == Vector2(23,19), "Both purchase hitboxes preserved")
	await snap("modifiers-shop-overclock")
	set_money(999)
	await click_control(offer)
	check(not manager.available_modifiers.has(first) and main._extra_inventory.modifiers.has(first), "Illustrated offer purchase keeps normal inventory route")
	check(extra_offer._modifier_visual_offset == Vector2.ZERO, "Single remaining overclock offer recenters its art")
	manager.available_modifiers.assign([first, extra])
	shop._refresh_modifiers_shop()
	await settle()
	await click_control(extra_offer)
	check(manager.available_modifiers.has(first) and not manager.available_modifiers.has(extra), "Extra purchase selects its original hitbox")
	check(offer._modifier_visual_offset == Vector2.ZERO, "Single remaining normal offer recenters its art")
	manager.available_modifiers.assign([legacy_modifier()])
	shop._refresh_modifiers_shop()
	await settle()
	check(offer._modifier_icon == null and offer.clip_contents and offer._modifier_overlay.texture == null and offer._placeholder_label.visible, "Legacy modifier replaces art without stale decoration")
	manager.available_modifiers.clear()
	shop._refresh_modifiers_shop()
	await settle()
	check(offer._modifier_icon == null and offer.clip_contents and offer._modifier_overlay.texture == null and not offer._slot_sprite.visible and offer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Empty shop offer clears decoration and input")
	await verify_bundle_fallbacks()
	await verify_batch02()
	var report := FileAccess.open("res://tests/slot-presentation-results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(cases, "\t"))
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func verify_batch02() -> void:
	var keys := ["charger", "condenser", "resonator", "conector", "stabilizer", "accumulator", "igniter", "pressurizer", "refractor", "catalyzer", "dispenser", "enhancer", "purifier", "transmuter"]
	var tooltip: TooltipManager = get_first_node_in_group("tooltip_manager")
	var shop: ShopUI = main.shop_ui
	var manager: ShopManager = main.get_shop_manager()
	for index in keys.size():
		var key: String = keys[index]
		var data := modifier(key)
		main._on_view_panel_requested()
		main._extra_inventory.clear_all()
		main._extra_inventory.add_modifier(data)
		await settle()
		var item := inventory_item(data)
		check(item != null and item.has_modifier_icon() and not item.has_modifier_border(), key + " inventory uses approved kit")
		check(item.texture == data.icon and item._modifier_overlay.texture == null and not (item.get_parent() as SlotUI)._slot_sprite.visible, key + " inventory resolves exact resource")
		await move_mouse(Vector2(620,15))
		await snap("bundle-inventory-" + key)
		check(item.size == Vector2(40,40) and item.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, key + " native inventory pixels and hitbox")
		await move_mouse(center(item))
		check(tooltip._item_text.contains(data.display_name), key + " real inventory hover tooltip")
		await button(true)
		await move_mouse(pointer + Vector2(16,0), true)
		await move_mouse(Vector2(380,260), true)
		check_real_kit_drag(item, data, key)
		await snap("bundle-drag-" + key)
		await move_mouse(Vector2(620,15), true)
		await button(false)
		check(main._extra_inventory.modifiers.has(data) and not viewport.gui_is_dragging(), key + " cancelled drag conserves item")
		var locked: SlotUI = main.grid_ui_slots[Vector2i(4,4)]
		await drag_modifier(item, locked)
		check(main._extra_inventory.modifiers.has(data), key + " locked rejection conserves item")
		var coord := Vector2i(index % 3, (index % 9) / 3)
		var target: SlotUI = main.grid_ui_slots[coord]
		var model: GridSlot = main.grid_manager.get_slot(coord)
		if not model.rune:
			main.grid_manager.place_rune_instance(make_rune(), coord)
			await settle()
		var held_rune: RuneInstance = model.rune
		check(held_rune != null, key + " conservation case starts with occupied target")
		await drag_modifier(item, target)
		check(model.slot.slot_modifier_id == data.id and not main._extra_inventory.modifiers.has(data), key + " real drop applies and consumes item")
		check(model.rune == held_rune, key + " modifier replacement preserves held rune")
		check(target._modifier_overlay.texture == data.slot_data_override.modifier_overlay_texture, key + " drop updates visible border")
		check(target.size == Vector2(40,40) and target._modifier_overlay.position == Vector2(20,20), key + " panel alignment and hitbox unchanged")
		await settle()
		main._on_enter_shop_pressed()
		await settle()
		var extra := modifier(keys[(index+1)%keys.size()]).duplicate() as SlotModifierData
		extra.set_meta("shop_overclock_offer", true)
		manager.overclock_purchased_this_round = true
		manager.available_modifiers.assign([data, extra])
		shop._refresh_modifiers_shop()
		await settle()
		var offer: SlotUI = shop.purchasable_modifiers_container.get_child(0)
		var extra_offer: SlotUI = shop.purchasable_modifiers_container.get_child(1)
		check(offer._modifier_icon != null and offer._modifier_icon.texture == data.icon and offer._modifier_overlay.texture == null, key + " shop resolves approved art")
		check(extra_offer._modifier_icon != null and extra_offer._modifier_icon.texture == extra.icon and extra_offer._modifier_overlay.texture == null, key + " extra shop resolves approved art")
		check(extra_offer._modifier_icon.global_position.x - offer._modifier_icon.global_position.x == 34, key + " dual kits retain natural pitch34")
		check(offer.size == Vector2(23,19) and extra_offer.size == Vector2(23,19), key + " shop click regions unchanged")
		await move_mouse(center(offer))
		check(tooltip._rune_text.contains(data.display_name) and not offer.get_shop_price_text().is_empty(), key + " shop hover retains name and price")
		set_money(0)
		await click_control(offer)
		check(manager.available_modifiers.has(data), key + " insufficient mana retains offer")
		await move_mouse(Vector2(620,15))
		await check_rendered_shop_kit(offer, data, key)
		await check_rendered_shop_kit(extra_offer, extra, key + " Extra")
		await snap("batch02-shop-" + key)
		set_money(999)
		# Buy both positions for every kit; each remaining solo retains its center.
		await click_control(offer)
		check(not manager.available_modifiers.has(data) and main._extra_inventory.modifiers.has(data), key + " normal click purchases exact modifier")
		check(extra_offer._modifier_icon != null and extra_offer._modifier_icon.position == Vector2(11,9) and extra_offer._modifier_visual_offset == Vector2.ZERO, key + " solo Extra remains centered")
		manager.available_modifiers.assign([data, extra])
		shop._refresh_modifiers_shop()
		await settle()
		await click_control(extra_offer)
		check(manager.available_modifiers.has(data) and not manager.available_modifiers.has(extra), key + " Extra click purchases exact modifier")
		check(offer._modifier_icon != null and offer._modifier_icon.position == Vector2(11,9) and offer._modifier_visual_offset == Vector2.ZERO, key + " solo normal remains centered")
		# Rune rerolls must retain the modifier offer and its kit.
		var before_reroll: int = root.get_node("Stats").get_money()
		await click_control(shop.get_node("ElementPedestals/Repeat") as Control)
		check(root.get_node("Stats").get_money() == before_reroll - 1 and manager.available_modifiers.has(data) and offer._modifier_icon.texture == data.icon, key + " real rune reroll retains modifier and kit")
		# Sell the purchased inventory kit through the actual fountain drop route.
		var sold_item := inventory_item(data)
		var before_sell: int = root.get_node("Stats").get_money()
		await drag_modifier(sold_item, shop.sell_area)
		check(not main._extra_inventory.modifiers.has(data) and root.get_node("Stats").get_money() == before_sell + ShopConfig.get_modifier_sell_price(data), key + " kit sale conserves inventory and credits normal price")
		manager.available_modifiers.clear()
		shop._refresh_modifiers_shop()
		await settle()
		check(offer._modifier_icon == null and extra_offer._modifier_icon == null and offer.clip_contents and extra_offer.clip_contents and offer._modifier_overlay.texture == null and extra_offer._modifier_overlay.texture == null, key + " cleared offers leave no kit or border and restore clipping")
	main._on_view_panel_requested()
	await settle()
	await move_mouse(Vector2(620,15))
	await snap("batch02-panel-mixed")


func check_real_kit_drag(item: ItemUI, data: SlotModifierData, key: String) -> void:
	check(viewport.gui_is_dragging() and viewport.gui_get_drag_data().get("modifier_data") == data, key + " real kit drag retains original modifier data")
	var found := false
	for node in root.find_children("*", "TextureRect", true, false):
		if node == item or node.texture != data.icon or not node.is_visible_in_tree():
			continue
		var preview := node as TextureRect
		var no_mounted_layer := true
		for child in preview.get_parent().get_children():
			if child is Sprite2D:
				no_mounted_layer = false
			if child is ColorRect and child.color.a != 0.0:
				no_mounted_layer = false
		found = preview.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED and preview.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and preview.position == -0.5 * item.size and no_mounted_layer
	check(found, key + " actual drag preview uses native centered kit without mounted layer")


func check_rendered_shop_kit(offer: SlotUI, data: SlotModifierData, key: String) -> void:
	check(offer._modifier_icon != null and offer._modifier_icon.position == Vector2(11,9) and offer._modifier_icon.scale == Vector2.ONE and offer._modifier_visual_offset == Vector2.ZERO, key + " native shop kit uses natural integer center")
	check(not offer.clip_contents and not offer._slot_sprite.visible and offer._modifier_overlay.texture == null, key + " shop kit has no base and visual overflow does not clip")
	if not capture:
		return
	await RenderingServer.frame_post_draw
	var frame := viewport.get_texture().get_image()
	var source := data.icon.get_image()
	var origin := Vector2i(offer._modifier_icon.global_position) - Vector2i(16,16)
	var exact := true
	var samples := 0
	for y in source.get_height():
		for x in source.get_width():
			var pixel := source.get_pixel(x,y)
			if pixel.a == 1.0:
				exact = exact and frame.get_pixelv(origin + Vector2i(x,y)).is_equal_approx(pixel)
				samples += 1
	check(exact and samples > 0, key + " rendered kit pixels exact including pixels outside purchase hitbox")
	if data.id == "slot_transmuter":
		check_transmuter_seals(frame, source, origin)


func verify_bundle_fallbacks() -> void:
	var shop: ShopUI = main.shop_ui
	var manager: ShopManager = main.get_shop_manager()
	var data := modifier("conector")
	var mounted := data.duplicate() as SlotModifierData
	mounted.icon = null
	var extra := mounted.duplicate() as SlotModifierData
	extra.set_meta("shop_overclock_offer", true)
	manager.available_modifiers.assign([mounted, extra])
	manager.overclock_purchased_this_round = true
	shop._refresh_modifiers_shop()
	await settle()
	var offer: SlotUI = shop.purchasable_modifiers_container.get_child(0)
	check(offer._modifier_icon == null and offer._modifier_overlay.texture == mounted.slot_data_override.modifier_overlay_texture and offer._modifier_visual_offset == Vector2(-7,0), "No-kit authored modifier retains mounted shop fallback")
	manager.available_modifiers.assign([data])
	shop._refresh_modifiers_shop()
	await settle()
	check(offer._modifier_icon.texture == data.icon and offer._modifier_visual_offset == Vector2.ZERO and offer._modifier_overlay.texture == null, "Mounted fallback to kit clears old border and offset")
	for context in [SlotUI.SlotContext.PANEL, SlotUI.SlotContext.INVENTORY, SlotUI.SlotContext.RELIC, SlotUI.SlotContext.SHOP]:
		offer.set_modifier_icon_display(data.icon)
		offer.set_slot_context(context)
		check(offer._modifier_icon == null and offer.clip_contents and offer._slot_sprite.visible, "Context switch removes kit and restores base/clipping")
	shop._refresh_modifiers_shop()
	main._on_view_panel_requested()
	main._extra_inventory.clear_all()
	main._extra_inventory.add_modifier(mounted)
	await settle()
	var item := inventory_item(mounted)
	check(item.has_modifier_border() and not item.has_modifier_icon() and item.texture == mounted.slot_data_override.texture, "No-kit authored modifier retains mounted inventory fallback")
	item.set_modifier(data)
	check(item.has_modifier_icon() and not item.has_modifier_border() and not (item.get_parent() as SlotUI)._slot_sprite.visible, "Reused inventory item switches mounted fallback to kit")
	item.set_modifier(legacy_modifier())
	check(not item.has_modifier_icon() and not item.has_modifier_border() and item.texture == null and (item.get_parent() as SlotUI)._slot_sprite.visible and (item.get_parent() as SlotUI).clip_contents, "Kit to legacy placeholder restores inventory base and clipping")
	item.set_modifier(data)
	item.clear()
	check(item.texture == null and (item.get_parent() as SlotUI)._slot_sprite.visible and (item.get_parent() as SlotUI).clip_contents, "Inventory kit clear restores empty base and clipping")
	main._extra_inventory.clear_all()
	await settle()

func verify_batch04_mounted() -> void:
	var keys := ["catalyzer", "dispenser", "enhancer"]
	var previous := ["accumulator", "conector", "stabilizer"]
	for index in keys.size():
		var coord := Vector2i(index,0)
		var model: GridSlot = main.grid_manager.get_slot(coord)
		model.remove_rune()
		check(model.slot.apply_modifier(modifier(keys[index])), keys[index] + " new mounted art applies")
		main._on_grid_slot_changed(coord)
		check_native_geometry(main.grid_ui_slots[coord], keys[index])
	await settle()
	await move_mouse(Vector2(620,15))
	await snap("batch04-empty-trio")
	await check_batch04_composition(keys, false)
	for index in keys.size():
		main.grid_manager.place_rune_instance(RuneInstance.new(load("res://resources/runes/common/rune_rocha.tres")), Vector2i(index,0))
	await settle()
	await snap("batch04-occupied-trio")
	await check_batch04_composition(keys, true)
	for index in keys.size():
		var cell: SlotUI = main.grid_ui_slots[Vector2i(index,0)]
		check(cell.size == Vector2(40,40) and cell.rune_ui.size == Vector2(40,40) and cell.rune_ui.stretch_mode == TextureRect.STRETCH_KEEP_CENTERED and cell.rune_ui.texture.get_size() == Vector2(32,32), keys[index] + " native32 rune within unchanged40 input region")
		check(cell._modifier_overlay.z_index < cell.rune_ui.z_index and cell.rune_ui.z_index < cell.multi_effect_overlay.z_index, keys[index] + " equipment-rune-highlight drawing order")
	var dispenser: SlotUI = main.grid_ui_slots[Vector2i(1,0)]
	var preserved: RuneInstance = dispenser.rune_ui.rune_instance
	await grab(dispenser.rune_ui)
	await move_mouse(Vector2(620,15), true)
	await button(false)
	check(dispenser.rune_ui.z_index == 2 and not dispenser.rune_ui.is_dragging_rune(), "Dispenser real rune drag cancellation restores z2")
	check(dispenser.rune_ui.rune_instance == preserved and dispenser._modifier_overlay.visible, "Dispenser cancelled rune drag preserves instance and equipment")
	await verify_residue_above_rune()
	# Keep the established nine-type board for its existing interaction cases.
	for index in previous.size():
		var coord := Vector2i(index,0)
		main.grid_manager.get_slot(coord).slot.apply_modifier(modifier(previous[index]))
		main._on_grid_slot_changed(coord)
	await settle()

func check_batch04_composition(keys: Array, occupied: bool, folder: String = "batch04") -> void:
	for index in keys.size():
		var cell: SlotUI = main.grid_ui_slots[Vector2i(index,0)]
		check(cell._modifier_overlay.visible and cell._modifier_overlay.texture == modifier(keys[index]).slot_data_override.modifier_overlay_texture, keys[index] + " mounted overlay remains visible at occupancy " + str(occupied))
	if not capture:
		return
	await RenderingServer.frame_post_draw
	var frame := viewport.get_texture().get_image()
	var rock: Image = load("res://sprites/runes/rocha.png").get_image()
	for index in keys.size():
		var cell: SlotUI = main.grid_ui_slots[Vector2i(index,0)]
		var expected: Image = load("res://sprites/slots/modifiers/" + folder + "/" + keys[index] + ".png").get_image()
		if occupied:
			expected.blend_rect(rock, Rect2i(0,0,32,32), Vector2i(4,4))
		var exact := true
		var samples := 0
		for y in 40:
			for x in 40:
				var pixel := expected.get_pixel(x,y)
				if pixel.a == 1.0:
					exact = exact and frame.get_pixelv(Vector2i(cell.global_position) + Vector2i(x,y)).is_equal_approx(pixel)
					samples += 1
		check(exact and samples > 0, keys[index] + " exact approved composition base-equipment-rune occupancy " + str(occupied))

func verify_residue_above_rune() -> void:
	var coord := Vector2i(1,0)
	var cell: SlotUI = main.grid_ui_slots[coord]
	var model: GridSlot = main.grid_manager.get_slot(coord)
	var held_rune: RuneInstance = model.rune
	var base: Image
	if capture:
		await RenderingServer.frame_post_draw
		base = viewport.get_texture().get_image()
	await snap("batch04-dispenser-without-residue")
	for residue_id in ["mana_residue", "mana_anomaly"]:
		model.slot.apply_residue(residue_id)
		main._on_grid_slot_changed(coord)
		await settle()
		check(cell.residue_visual.visible and cell.residue_visual.get_current_residue_id() == residue_id and cell.residue_visual.z_index == cell.rune_ui.z_index and cell.residue_visual.get_index() > cell.rune_ui.get_index(), residue_id + " real residue material above occupied rune")
		check(cell.multi_effect_overlay.z_index > cell.residue_visual.z_index and model.rune == held_rune, residue_id + " preserves highlight priority and rune state")
		await snap("batch04-dispenser-" + residue_id)
		if capture:
			await RenderingServer.frame_post_draw
			var frame := viewport.get_texture().get_image()
			var rock: Image = cell.rune_ui.texture.get_image()
			var changed := 0
			# Opaque central rune pixels occlude a wrongly ordered effect at every TIME.
			for y in range(12,28):
				for x in range(12,28):
					if rock.get_pixel(x-4,y-4).a == 1.0:
						var point := Vector2i(cell.global_position) + Vector2i(x,y)
						if not frame.get_pixelv(point).is_equal_approx(base.get_pixelv(point)):
							changed += 1
			check(changed > 32, residue_id + " shader visibly renders over opaque rune center")
		model.slot.clear_residues()
		main._on_grid_slot_changed(coord)
		await settle()
		check(not cell.residue_visual.visible and cell.residue_visual.material == null, residue_id + " removal clears visual material")
		await check_batch04_composition(["catalyzer", "dispenser", "enhancer"], true)

func legacy_modifier() -> SlotModifierData:
	var original := modifier("purifier")
	var copy := original.duplicate() as SlotModifierData
	copy.icon = null
	copy.slot_data_override = original.slot_data_override.duplicate() as SlotData
	copy.slot_data_override.texture = null
	copy.slot_data_override.modifier_overlay_texture = null
	check(original.icon != null and original.slot_data_override.texture != null and original.slot_data_override.modifier_overlay_texture != null, "Legacy fixture leaves official Purifier art intact")
	return copy

func verify_batch05_mounted() -> void:
	var keys := ["purifier", "transmuter"]
	var previous := ["accumulator", "conector"]
	for index in keys.size():
		var coord := Vector2i(index,0)
		var model: GridSlot = main.grid_manager.get_slot(coord)
		model.remove_rune()
		check(model.slot.apply_modifier(modifier(keys[index])), keys[index] + " final mounted art applies")
		main._on_grid_slot_changed(coord)
		check_native_geometry(main.grid_ui_slots[coord], keys[index])
	await settle()
	await move_mouse(Vector2(620,15))
	await snap("batch05-empty-pair")
	await check_batch04_composition(keys, false, "batch05")
	for index in keys.size():
		main.grid_manager.place_rune_instance(RuneInstance.new(load("res://resources/runes/common/rune_rocha.tres")), Vector2i(index,0))
	await settle()
	await snap("batch05-occupied-pair")
	await check_batch04_composition(keys, true, "batch05")
	for index in previous.size():
		var coord := Vector2i(index,0)
		main.grid_manager.get_slot(coord).slot.apply_modifier(modifier(previous[index]))
		main._on_grid_slot_changed(coord)
	await settle()

func check_transmuter_seals(frame: Image, source: Image, origin: Vector2i) -> void:
	# Approved TR-kit elemental ROIs from its source manifest, in source pixel coordinates.
	var names := ["FIRE", "WATER", "EARTH", "AIR", "SPIRIT"]
	var positions := [Vector2i(5,6), Vector2i(13,6), Vector2i(21,6), Vector2i(9,13), Vector2i(17,13)]
	for index in names.size():
		var exact := true
		var count := 0
		for y in 5:
			for x in 5:
				var point: Vector2i = positions[index] + Vector2i(x,y)
				var pixel := source.get_pixelv(point)
				if pixel.a == 1.0:
					exact = exact and frame.get_pixelv(origin + point).is_equal_approx(pixel)
					count += 1
		check(exact and count > 0, "Transmuter " + names[index] + " seal fully visible with exact rendered native pixels")
