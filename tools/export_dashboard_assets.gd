extends SceneTree

## Exports item sprites + a manifest.json for the balancing dashboard (tools/dashboard/).
## Run headless from the project root:
##   godot --headless --path . -s tools/export_dashboard_assets.gd
## Re-run whenever runes/relics/pieces/modifiers are added or their art changes.


func _initialize() -> void:
	_run()
	quit()

const OUT_DIR = "res://tools/dashboard/assets"

const RUNE_FOLDERS = [
	"res://resources/runes/common/",
	"res://resources/runes/uncommon/",
	"res://resources/runes/rare/",
	"res://resources/runes/epic/",
	"res://resources/runes/legendary/",
]


func _run() -> void:
	var manifest := {}
	var exported := 0
	var missing := 0

	for folder in RUNE_FOLDERS:
		for res in _load_folder(folder):
			var rune := res as RuneData
			if not rune or rune.id == "":
				continue
			var tex: Texture2D = null
			if rune.textures.size() > 0:
				tex = rune.textures[clampi(rune.tier - 1, 0, rune.textures.size() - 1)]
			var sprite := _save_sprite(tex, "rune", rune.id)
			manifest["rune:%s" % rune.id] = {
				"name": rune.rune_name,
				"rarity": GameEnums.Rarity.keys()[rune.rarity],
				"tier": int(rune.tier),
				"elements": rune.elements.map(func(e): return GameEnums.Element.keys()[e]),
				"description": rune.description,
				"sprite": sprite,
			}
			exported += 1 if sprite != "" else 0
			missing += 1 if sprite == "" else 0

	for res in _load_folder("res://resources/relics/"):
		var relic := res as RelicData
		if not relic or relic.id == "":
			continue
		var sprite := _save_sprite(relic.icon, "relic", relic.id)
		manifest["relic:%s" % relic.id] = {
			"name": relic.display_name,
			"rarity": GameEnums.Rarity.keys()[relic.rarity],
			"description": relic.description,
			"sprite": sprite,
		}
		exported += 1 if sprite != "" else 0
		missing += 1 if sprite == "" else 0

	for res in _load_folder("res://resources/slot_pieces/"):
		var piece := res as SlotPieceData
		if not piece or piece.id == "":
			continue
		var sprite := _save_sprite(piece.icon, "slot_piece", piece.id)
		manifest["slot_piece:%s" % piece.id] = {
			"name": piece.display_name,
			"rarity": GameEnums.Rarity.keys()[piece.rarity],
			"description": piece.description,
			"slots": piece.get_slot_count(),
			"sprite": sprite,
		}
		exported += 1 if sprite != "" else 0
		missing += 1 if sprite == "" else 0

	for res in _load_folder("res://resources/slot_modifiers/"):
		var modifier := res as SlotModifierData
		if not modifier or modifier.id == "":
			continue
		var sprite := _save_sprite(modifier.icon, "slot_modifier", modifier.id)
		manifest["slot_modifier:%s" % modifier.id] = {
			"name": modifier.display_name,
			"rarity": GameEnums.Rarity.keys()[modifier.rarity],
			"description": modifier.description,
			"sprite": sprite,
		}
		exported += 1 if sprite != "" else 0
		missing += 1 if sprite == "" else 0

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var file = FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	# .js wrapper because fetch() of local JSON is blocked on file:// pages
	file = FileAccess.open("%s/manifest.js" % OUT_DIR, FileAccess.WRITE)
	file.store_string("window.RUNES_MANIFEST = %s;\n" % JSON.stringify(manifest))
	file.close()
	print("[DashboardAssets] %d items in manifest, %d sprites exported, %d without art -> %s/manifest.json" % [
		manifest.size(), exported, missing, OUT_DIR
	])


func _load_folder(folder: String) -> Array:
	var resources: Array = []
	var dir = DirAccess.open(folder)
	if not dir:
		return resources
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var res = load(folder + file_name.replace(".remap", ""))
			if res:
				resources.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return resources


## Saves the texture as assets/<type>/<id>.png and returns the manifest-relative path ("" if no texture)
func _save_sprite(tex: Texture2D, item_type: String, id: String) -> String:
	if not tex:
		return ""
	var img := tex.get_image()
	if not img:
		return ""
	if img.is_compressed():
		img.decompress()
	var rel := "%s/%s.png" % [item_type, id]
	var abs_dir := ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, item_type])
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var err := img.save_png("%s/%s.png" % [abs_dir, id])
	if err != OK:
		push_warning("[DashboardAssets] Failed to save %s (%d)" % [rel, err])
		return ""
	return rel
