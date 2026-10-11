extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

const ArenaFile := preload("res://avast/api/defs/arena_file.gd")
const _FOLDER := "res://scenes/game_object/folder/folder.tscn"
const _SCRIPT := preload("res://avast/api/ui/custom_file.gd")
const TABLES: Array[String] = ["small_files", "script_files", "archives", "installers", "special_events", "powerups"]

static var _files := {}
static var _hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)

func add(file: ArenaFile) -> PackedScene:
	var id := file.id
	var def := file._def
	var table: int = def.get("table", ArenaFile.Table.SMALL)
	var mod := _mod
	var scene := Defs.repack(load(_FOLDER), _mod.path("files/%s.tscn" % id), func(root: Node) -> void:
		root.set_script(_SCRIPT)
		root.file_id = id
		root._folder_name = str(def.get("title", id))
		var tex := Defs.texture(mod, def.get("icon"))
		if tex != null:
			var sprite: Sprite2D = root.get_node("Sprite2D")
			sprite.texture = tex
			sprite.scale = Vector2.ONE * 32.0 / maxf(tex.get_width(), tex.get_height())
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST)
	if scene == null:
		return null
	var old: Dictionary = _files.get(id, {})
	_files[id] = {"def": def, "scene": scene, "table": TABLES[table], "weight": int(def.get("weight", 5))}
	_hook()
	var rm := Game.round_manager()
	if rm != null:
		if not old.is_empty():
			rm.get(old.table).remove_item(old.scene)
		_add_to_table(rm, _files[id])
	return scene

func spawn(id: String, at: Variant = null) -> Node2D:
	var rm := Game.round_manager()
	if not _files.has(id) or rm == null:
		if not _files.has(id):
			push_warning("[%s] files.spawn: unknown file '%s'" % [_mod.mod_id, id])
		return null
	var file: Node2D = _files[id].scene.instantiate()
	if at is Vector2:
		file.position = at
	else:
		rm.gen_level.place_node_randomly(file)
	rm.icons_layer.add_child(file)
	return file

func has(id: String) -> bool:
	return _files.has(id)

func list() -> Array[String]:
	var out: Array[String] = []
	out.assign(_files.keys())
	out.sort()
	return out

static func get_def(id: String) -> Dictionary:
	return _files.get(id, {}).get("def", {})

static func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	Game.tree().node_added.connect(func(node: Node) -> void:
		if node.scene_file_path == Game.MAIN:
			node.ready.connect(_fill_tables, Object.CONNECT_ONE_SHOT))

static func _fill_tables() -> void:
	var rm := Game.round_manager()
	for id in _files:
		_add_to_table(rm, _files[id])

static func _add_to_table(rm: Node, entry: Dictionary) -> void:
	var table = rm.get(entry.table)
	if entry.weight > 0 and not table.contains_item(entry.scene):
		table.add_item(entry.scene, entry.weight)

static func _release() -> void:
	_files.clear()
