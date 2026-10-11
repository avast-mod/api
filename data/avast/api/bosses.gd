extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Enemies := preload("res://avast/api/enemies.gd")

const Boss := preload("res://avast/api/defs/boss.gd")
const GLUE := preload("res://avast/api/entities/custom_boss.gd")

const VANILLA := {
	"beachball": "res://scenes/game_object/bosses/beachball_boss/beachball_boss.tscn",
	"bonzi": "res://scenes/game_object/bosses/bonzi_boss/bonzi_boss.tscn",
	"recycle_bin": "res://scenes/game_object/bosses/recycle_bin_boss/recycle_bin_boss.tscn",
}

const _BOSS_BASE := "res://scenes/game_object/bosses/boss_base.gd"
const _BOSS_FILE := "res://scenes/game_object/clickables/boss_files/beachball_boss_file.tscn"

static var _scenes := {}
static var _defs := {}
static var _choices := {}
static var _hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)

func add(boss: Boss) -> PackedScene:
	var id := boss.id
	var def := boss._def
	var base := scene(str(def.get("base", "beachball")))
	if base == null:
		push_warning("[%s] bosses.add('%s'): unknown base '%s'. Valid: %s" % [_mod.mod_id, id, def.get("base"), VANILLA.keys()])
		return null
	var prepared := Enemies.prepare(_mod, def)
	_defs[id] = prepared
	var packed := Defs.repack(base, _mod.path("bosses/%s.tscn" % id), func(root: Node) -> void:
		if not def.get("keep_ai", true):
			Defs.swap_script(root, load(_BOSS_BASE))
		var boss_scale: Variant = prepared.get("scale")
		prepared.erase("scale")
		Enemies.build(_mod, root, prepared)
		if boss_scale != null:
			for node in [root.get_node_or_null("Visuals/Sprite2D"), root.get_node_or_null("Shadow")]:
				if node != null:
					node.scale = Vector2.ONE * float(boss_scale)
		var glue: Node = root.get_node_or_null("AVaStGlue")
		if glue == null:
			glue = GLUE.new()
			glue.name = "AVaStGlue"
			root.add_child(glue)
			glue.owner = root
		glue.custom_id = id)
	if packed == null:
		_defs.erase(id)
		return null
	_scenes[id] = packed
	if def.get("choice", true):
		_choices[id] = {
			"path": packed.resource_path,
			"title": str(def.get("title", id)),
			"icon": Defs.texture(_mod, def.get("icon", def.get("sprite"))),
		}
		_hook_choice()
	else:
		_choices.erase(id)
	return packed

func start(id: String) -> bool:
	var sc := scene(id)
	var rm := Game.round_manager()
	if sc == null or rm == null or rm.boss_phase_active:
		return false
	rm.commit_boss_choice(sc)
	return true

func current() -> Node2D:
	var rm := Game.round_manager()
	if rm == null or not rm.boss_phase_active:
		return null
	return Game.first_in_group("boss") as Node2D

func scene(id: String) -> PackedScene:
	if _scenes.has(id):
		return _scenes[id]
	return load(VANILLA[id]) if VANILLA.has(id) else null

func has(id: String) -> bool:
	return _scenes.has(id) or VANILLA.has(id)

func list() -> Array[String]:
	var out: Array[String] = []
	out.assign(VANILLA.keys() + _scenes.keys())
	out.sort()
	return out

static func get_def(id: String) -> Dictionary:
	return _defs.get(id, {})

static func _hook_choice() -> void:
	if _hooked:
		return
	_hooked = true
	Game.autoload("GameEvents").battle_folder_opened.connect(func() -> void:
		var atm := Game.first_in_group("arena_time_manager")
		if atm != null and not atm.arena_timer_finished.is_connected(_on_arena_timer_finished):
			atm.arena_timer_finished.connect(_on_arena_timer_finished))

static func _on_arena_timer_finished() -> void:
	_add_choice_files.call_deferred()

static func _add_choice_files() -> void:
	var rm := Game.round_manager()
	if rm == null or rm.boss_choice_files.is_empty():
		return
	var center: Node2D = rm.boss_choice_files[0]
	for id in _choices:
		var choice: Dictionary = _choices[id]
		var file: Node2D = load(_BOSS_FILE).instantiate()
		file.boss_scene_path = choice.path
		file.boss_id = ""
		file.name_key = choice.title
		file.icon = choice.icon
		rm.gen_level.place_node_in_ring(file, center.global_position, 48.0, 110.0)
		rm.icons_layer.add_child(file)
		file.boss_committed.connect(rm.commit_boss_choice)
		rm.boss_choice_files.append(file)

static func _release() -> void:
	_defs.clear()
