extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Starter := preload("res://avast/api/lib/starter.gd")
const CursorClass := preload("res://avast/api/defs/cursor_class.gd")

const VANILLA := {
	"default": "res://resources/classes/base_player_class.tres",
	"brick": "res://resources/classes/brick_player_class.tres",
	"vector": "res://resources/classes/vector_player_class.tres",
	"null": "res://resources/classes/null_player_class.tres",
	"breakpoint": "res://resources/classes/breakpoint_player_class.tres",
	"thread": "res://resources/classes/thread_player_class.tres",
	"admin": "res://resources/classes/admin_player_class.tres",
}
const _MODIFIERS: Array[String] = ["flat_modifiers", "additive_modifiers", "multiplicative_modifiers"]

static var _classes := {}

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: CursorClass) -> PlayerClass:
	var def := definition._def
	var player_class: PlayerClass
	if def.has("base"):
		var base := find(str(def.base))
		if base == null:
			push_warning("[%s] classes.add('%s'): unknown base '%s'. See classes.list()" % [_mod.mod_id, definition.id, def.base])
			return null
		player_class = base.duplicate(true)
	else:
		player_class = PlayerClass.new()
	player_class.id = definition.id
	for key in def:
		if key in ["base", "starter"]:
			continue
		if key == "cursor_texture":
			player_class.cursor_texture = Defs.texture(_mod, def[key])
		elif key in _MODIFIERS:
			var table: Dictionary = player_class.get(key).duplicate()
			for stat in def[key]:
				table[stat] = float(def[key][stat])
			player_class.set(key, table)
		elif key in Defs.script_props(player_class):
			player_class.set(key, def[key])
		else:
			push_warning("[%s] classes.add('%s'): '%s' is not a field of PlayerClass" % [_mod.mod_id, definition.id, key])
	_classes[definition.id] = player_class
	if def.get("starter", true):
		Starter.add_class(player_class)
	else:
		Starter.remove_class(definition.id)
	return player_class

func select(id: String) -> bool:
	var player_class := find(id)
	if player_class == null:
		return false
	Game.autoload("StatsManager").set_class(player_class)
	Game.autoload("GameEvents").emit_class_picked(player_class)
	var cursor := Game.player()
	if cursor is Cursor and player_class.cursor_texture != null:
		cursor.apply_cursor_texture(player_class.cursor_texture)
	return true

func current() -> String:
	var picked: PlayerClass = Game.autoload("GameEvents").picked_class
	return picked.id if picked != null else ""

func find(id: String) -> PlayerClass:
	if _classes.has(id):
		return _classes[id]
	return load(VANILLA[id]) if VANILLA.has(id) else null

func has(id: String) -> bool:
	return _classes.has(id) or VANILLA.has(id)

func list() -> Array[String]:
	var out: Array[String] = []
	out.assign(VANILLA.keys() + _classes.keys())
	out.sort()
	return out
