extends RefCounted

static var _buttons := {}

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func on_button(section: String, option: String, on_click: Callable) -> void:
	_buttons[_key(_mod.mod_id, section, option)] = on_click

static func has_button(mod_id: String, section: String, option: String) -> bool:
	var on_click: Variant = _buttons.get(_key(mod_id, section, option))
	return on_click is Callable and on_click.is_valid()

static func press(mod_id: String, section: String, option: String) -> bool:
	if not has_button(mod_id, section, option):
		return false
	_buttons[_key(mod_id, section, option)].call()
	return true

static func _key(mod_id: String, section: String, option: String) -> String:
	return "%s/%s/%s" % [mod_id, section, option]
