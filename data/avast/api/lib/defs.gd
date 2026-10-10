extends RefCounted

static func resolve_path(mod: Node, v: Variant) -> String:
	if not (v is String or v is StringName):
		return ""
	var p := str(v)
	if p.is_empty() or p.begins_with("res://") or p.begins_with("user://") or p.begins_with("uid://"):
		return p
	return mod.path(p) if mod != null and mod.has_method("path") else p

static func texture(mod: Node, v: Variant) -> Texture2D:
	if v == null or v is Texture2D:
		return v
	var p := resolve_path(mod, v)
	if ResourceLoader.exists(p):
		var res := load(p)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(p):
		var img := Image.new()
		var bytes := FileAccess.get_file_as_bytes(p)
		var err := FAILED
		match p.get_extension().to_lower():
			"png":
				err = img.load_png_from_buffer(bytes)
			"jpg", "jpeg":
				err = img.load_jpg_from_buffer(bytes)
			"webp":
				err = img.load_webp_from_buffer(bytes)
			"bmp":
				err = img.load_bmp_from_buffer(bytes)
			"svg":
				err = img.load_svg_from_buffer(bytes)
		if err == OK:
			return ImageTexture.create_from_image(img)
	_fail(mod, "texture", v)
	return null

static func sound(mod: Node, v: Variant) -> AudioStream:
	if v == null or v is AudioStream:
		return v
	var p := resolve_path(mod, v)
	if ResourceLoader.exists(p):
		var res := load(p)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(p):
		var stream: AudioStream = null
		match p.get_extension().to_lower():
			"ogg":
				stream = AudioStreamOggVorbis.load_from_file(p)
			"wav":
				stream = AudioStreamWAV.load_from_file(p)
			"mp3":
				stream = AudioStreamMP3.load_from_file(p)
		if stream != null:
			return stream
	_fail(mod, "sound", v)
	return null

static func scene(mod: Node, v: Variant) -> PackedScene:
	if v == null or v is PackedScene:
		return v
	var res := _load(resolve_path(mod, v))
	if res is PackedScene:
		return res
	_fail(mod, "scene", v)
	return null

static func script(mod: Node, v: Variant) -> Script:
	if v == null or v is Script:
		return v
	var res := _load(resolve_path(mod, v))
	if res is Script:
		return res
	_fail(mod, "script", v)
	return null

static func _load(p: String) -> Resource:
	return load(p) if not p.is_empty() and ResourceLoader.exists(p) else null

static func _fail(mod: Node, what: String, v: Variant) -> void:
	var id := str(mod.get("mod_id")) if mod != null else "avast"
	push_warning("[%s] could not load %s '%s'" % [id, what, str(v)])

static func script_props(obj: Object) -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in obj.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(p.name)
	return out

static func rarity_values(target: Dictionary, v: Variant) -> void:
	const NAMES := ["common", "uncommon", "rare", "epic", "legendary"]
	var values: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	if v is Array:
		for i in mini(v.size(), 5):
			values[i] = float(v[i])
	elif v is Dictionary:
		for key in v:
			var i: int = key if typeof(key) == TYPE_INT else NAMES.find(str(key).to_lower())
			if i >= 0 and i < 5:
				values[i] = float(v[key])
	target.clear()
	for i in 5:
		target[i] = values[i]

static func put_by_id(items: Array, item: Object) -> void:
	for i in items.size():
		if items[i] != null and items[i].get("id") == item.get("id"):
			items[i] = item
			return
	items.append(item)

static func find_by_id(items: Array, id: String) -> Object:
	for item in items:
		if item != null and item.get("id") == id:
			return item
	return null

static func repack(scene: PackedScene, path: String, edit: Callable) -> PackedScene:
	var root := scene.instantiate()
	edit.call(root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK:
		return null
	packed.take_over_path(path)
	return packed

static func swap_script(node: Object, new_script: Script) -> void:
	var saved := {}
	for name in script_props(node):
		saved[name] = node.get(name)
	node.set_script(new_script)
	for name in saved:
		if name in node:
			node.set(name, saved[name])

static func tinted(tex: Texture2D, color: Color) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, img.get_pixel(x, y) * color)
	return ImageTexture.create_from_image(img)

static func tint_sprite(sprite: Node, color: Color) -> void:
	if sprite is Sprite2D:
		sprite.texture = tinted(sprite.texture, color)
	elif sprite is AnimatedSprite2D and sprite.sprite_frames != null:
		var frames: SpriteFrames = sprite.sprite_frames.duplicate()
		for anim in frames.get_animation_names():
			for i in frames.get_frame_count(anim):
				frames.set_frame(anim, i, tinted(frames.get_frame_texture(anim, i), color), frames.get_frame_duration(anim, i))
		sprite.sprite_frames = frames
