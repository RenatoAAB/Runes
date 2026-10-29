extends RefCounted
## Separate floor/water receivers and object-specific 2.5D projections.
## No source textures are edited; invalid geometry safely disables all shadows.
const FLOOR_COLOR := Color8(50,51,83,255)
const FLOOR_POLYGON := [Vector2(18,92),Vector2(74,74),Vector2(220,74),Vector2(230,49),Vector2(357,49),Vector2(402,61),Vector2(585,83),Vector2(623,118),Vector2(640,274),Vector2(618,295),Vector2(32,295),Vector2(0,269)]
const FOOTPRINTS := [
	Vector4(317,208,96,54), # bowl; never blocks its own blue emitter
	Vector4(106,181,56,7), Vector4(100,230,61,7), # workbenches
	Vector4(495,101,18,6), Vector4(558,131,18,6), # crystal pedestals
	Vector4(526,194,43,22), # round relic altar in perspective
	Vector4(319,108,16,6), Vector4(239,137,16,6), Vector4(402,139,16,6),
	Vector4(241,228,16,6), Vector4(396,229,16,6), Vector4(319,270,16,6)
]
const LENGTHS := [34.0,40.0,44.0,22.0,24.0,14.0,22.0,22.0,22.0,22.0,22.0,22.0]

static func build(art: Node2D) -> Image:
	var background := art.get_node_or_null("Background") as Sprite2D
	if not background or not background.texture or not art.has_node("RelicAltar"):
		return null
	var source := background.texture.get_image()
	if not source or source.get_size() != Vector2i(640,360):
		return null
	source.convert(Image.FORMAT_RGBA8)
	var mask := Image.create(640,360,false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	var polygon := PackedVector2Array(FLOOR_POLYGON)
	for y in range(49,296):
		for x in 640:
			if source.get_pixel(x,y) == FLOOR_COLOR and Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon):
				mask.set_pixel(x,y,Color.WHITE)
	_exclude_art(art,art,background,mask)
	return mask

static func build_water(art: Node2D) -> Image:
	var water := art.get_node_or_null("FountainWater") as AnimatedSprite2D
	var background := art.get_node_or_null("Background") as Sprite2D
	if not water or not water.sprite_frames or not background:
		return null
	var frames: SpriteFrames = water.sprite_frames
	var count := frames.get_frame_count(water.animation)
	if count == 0:
		return null
	var first := frames.get_frame_texture(water.animation,0).get_image()
	if not first or first.get_size() != Vector2i(184,131):
		return null
	var mask := Image.create(640,360,false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	var transform: Transform2D = art.global_transform.affine_inverse()*water.global_transform
	var origin := water.offset - (Vector2(first.get_size())*0.5 if water.centered else Vector2.ZERO)
	# All-frame alpha intersection: no shadow leaks at a changing water silhouette.
	var images: Array[Image] = []
	for frame in count:
		var image := frames.get_frame_texture(water.animation,frame).get_image()
		if not image or image.get_size() != first.get_size():
			return null
		images.append(image)
	for y in first.get_height():
		for x in first.get_width():
			var opaque := true
			for image in images:
				if image.get_pixel(x,y).a < 1.0:
					opaque = false
					break
			if opaque:
				var point := Vector2i((transform*(origin+Vector2(x,y))).round())
				if Rect2i(0,0,640,360).has_point(point):
					mask.set_pixelv(point,Color.WHITE)
	_exclude_art(art,art,background,mask,water)
	return mask

static func build_foreground(art: Node2D) -> Image:
	var background := art.get_node_or_null("Background") as Sprite2D
	if not background or not background.texture or background.texture.get_size() != Vector2(640,360):
		return null
	# Native-pixel silhouettes of the elevated front rail and inventory chest.
	var rail := PackedVector2Array([Vector2(0,260),Vector2(34,283),Vector2(54,283),Vector2(55,293),Vector2(91,293),Vector2(93,284),Vector2(113,284),Vector2(115,293),Vector2(229,293),Vector2(232,284),Vector2(252,284),Vector2(253,293),Vector2(388,293),Vector2(388,360),Vector2(0,360)])
	var chest := PackedVector2Array([Vector2(417,220),Vector2(635,257),Vector2(640,274),Vector2(640,360),Vector2(383,360),Vector2(383,315)])
	var source := background.texture.get_image()
	source.convert(Image.FORMAT_RGBA8)
	var mask := Image.create(640,360,false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	for y in range(220,360):
		for x in 640:
			var point := Vector2(x+0.5,y+0.5)
			if source.get_pixel(x,y) != FLOOR_COLOR and (Geometry2D.is_point_in_polygon(point,rail) or Geometry2D.is_point_in_polygon(point,chest)):
				mask.set_pixel(x,y,Color.WHITE)
	return mask

static func _exclude_art(node: Node, art: Node2D, background: Sprite2D, mask: Image, skipped: Node = null) -> void:
	if node == background or node == skipped:
		return
	var texture: Texture2D
	var origin := Vector2.ZERO
	if node is Sprite2D:
		texture = node.texture
		origin = node.get_rect().position
	elif node is AnimatedSprite2D:
		texture = node.sprite_frames.get_frame_texture(node.animation,node.frame)
		origin = node.offset - (texture.get_size()*0.5 if node.centered else Vector2.ZERO)
	if texture:
		var image := texture.get_image()
		if node is Sprite2D and (node.hframes > 1 or node.vframes > 1):
			var size := Vector2i(image.get_width()/node.hframes,image.get_height()/node.vframes)
			image = image.get_region(Rect2i(node.frame_coords*size,size))
		image.convert(Image.FORMAT_RGBA8)
		var transform: Transform2D = art.global_transform.affine_inverse()*node.global_transform
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x,y).a > 0.0:
					var point := Vector2i((transform*(origin+Vector2(x,y))).round())
					if Rect2i(0,0,640,360).has_point(point):
						mask.set_pixelv(point,Color.TRANSPARENT)
	for child in node.get_children():
		_exclude_art(child,art,background,mask,skipped)
