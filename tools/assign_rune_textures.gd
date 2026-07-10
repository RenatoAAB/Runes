@tool
extends EditorScript
## Associa a textura visual de cada runa ao seu recurso RuneData.
##
## Para cada resources/runes/**/rune_<id>.tres, procura sprites/runes/<id>.png
## e o coloca em RuneData.textures[0]. Trata uid/import corretamente
## (ResourceSaver.save), então re-exportar o PNG depois só atualiza os pixels.
##
## Como rodar:
##   Godot > abra este arquivo no editor de script > menu File > Run
##   (ou Ctrl+Shift+X). Veja o resultado no painel Output.

const RUNES_DIR := "res://resources/runes"
const SPRITES_DIR := "res://sprites/runes"

func _run() -> void:
	var tres_paths := _find_files(RUNES_DIR, ".tres")
	var assigned := 0
	var missing_png: Array[String] = []
	var skipped: Array[String] = []

	for path in tres_paths:
		var res := ResourceLoader.load(path)
		if not (res is RuneData):
			continue
		var rune: RuneData = res
		var id := rune.id
		if id.is_empty():
			skipped.append(path + " (sem id)")
			continue

		var png_path := "%s/%s.png" % [SPRITES_DIR, id]
		if not ResourceLoader.exists(png_path):
			missing_png.append(id)
			continue

		var tex := ResourceLoader.load(png_path) as Texture2D
		if tex == null:
			missing_png.append(id + " (falha ao carregar)")
			continue

		# Só salva se mudou, pra não sujar o git à toa.
		if rune.textures.size() == 1 and rune.textures[0] == tex:
			continue

		rune.textures = [tex] as Array[Texture2D]
		var e := ResourceSaver.save(rune, path)
		if e == OK:
			assigned += 1
			print("  ✔ %s  ->  %s.png" % [path.get_file(), id])
		else:
			skipped.append("%s (erro save: %d)" % [path, e])

	print("\n=== assign_rune_textures ===")
	print("Texturas associadas/atualizadas: %d" % assigned)
	if not missing_png.is_empty():
		print("Sem PNG em sprites/runes/ (%d): %s" % [missing_png.size(), ", ".join(missing_png)])
	if not skipped.is_empty():
		print("Ignorados: %s" % ", ".join(skipped))
	print("Rode o import do Godot se algum PNG for novo (foco no editor já dispara).")


## Busca recursiva por arquivos com dada extensão sob 'dir' (res://...).
func _find_files(dir: String, ext: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		push_error("Não abriu diretório: " + dir)
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name != "." and name != "..":
			var full := dir + "/" + name
			if d.current_is_dir():
				out.append_array(_find_files(full, ext))
			elif name.ends_with(ext):
				out.append(full)
		name = d.get_next()
	d.list_dir_end()
	return out
