extends RefCounted

const CursorClass := preload("res://avast/api/defs/cursor_class.gd")

var id := ""
var _def := {}

func _init(class_id: String, base_id: String = "") -> void:
	id = class_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> CursorClass:
	_def.base = base_id
	return self

func name(value: String) -> CursorClass:
	_def.player_class_name = value
	return self

func description(value: String) -> CursorClass:
	_def.description = value
	return self

func cursor(texture: Variant) -> CursorClass:
	_def.cursor_texture = texture
	return self

func flat(stat: String, value: float) -> CursorClass:
	return _modifier("flat_modifiers", stat, value)

func percent(stat: String, value: float) -> CursorClass:
	return _modifier("additive_modifiers", stat, value)

func multiply(stat: String, value: float) -> CursorClass:
	return _modifier("multiplicative_modifiers", stat, value)

func passive(passive_id: String) -> CursorClass:
	_def.passive_id = passive_id
	return self

func starting_keys(count: int) -> CursorClass:
	_def.starting_keys = count
	return self

func in_starter(on: bool = true) -> CursorClass:
	_def.starter = on
	return self

func field(property: String, value: Variant) -> CursorClass:
	_def[property] = value
	return self

func _modifier(table: String, stat: String, value: float) -> CursorClass:
	if not _def.has(table):
		_def[table] = {}
	_def[table][stat] = value
	return self
