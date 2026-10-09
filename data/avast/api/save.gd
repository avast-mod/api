extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func available() -> bool:
	return Game.autoload("SaveManager").active_slot != 0

func set_value(key: String, value: Variant, write_now: bool = true) -> bool:
	var data = _data(true)
	if data == null:
		push_warning("[%s] save.set_value('%s'): no profile is loaded yet" % [_mod.mod_id, key])
		return false
	data[key] = var_to_str(value)
	if write_now:
		flush()
	return true

func get_value(key: String, default_value: Variant = null) -> Variant:
	var data = _data(false)
	if data == null or not data.has(key):
		return default_value
	return str_to_var(str(data[key]))

func has(key: String) -> bool:
	var data = _data(false)
	return data != null and data.has(key)

func erase(key: String, write_now: bool = true) -> bool:
	var data = _data(false)
	if data == null or not data.erase(key):
		return false
	if write_now:
		flush()
	return true

func flush() -> void:
	if available():
		Game.autoload("SaveManager").save_profile()

func _data(create: bool) -> Variant:
	if not available():
		return null
	var profile: Dictionary = Game.autoload("SaveManager").profile
	if not profile.has("mods"):
		if not create:
			return null
		profile["mods"] = {}
	if not profile.mods.has(_mod.mod_id):
		if not create:
			return null
		profile.mods[_mod.mod_id] = {}
	return profile.mods[_mod.mod_id]
