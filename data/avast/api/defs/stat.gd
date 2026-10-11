extends RefCounted

const Stat := preload("res://avast/api/defs/stat.gd")

var id := ""
var _def := {}

func _init(stat_id: String, base_value: float = 0.0) -> void:
	id = stat_id
	_def.base = base_value

func base(value: float) -> Stat:
	_def.base = value
	return self

func name(value: String) -> Stat:
	_def.name = value
	return self

func description(value: String) -> Stat:
	_def.description = value
	return self

func icon(value: Variant) -> Stat:
	_def.icon = value
	return self

func display_type(value: String) -> Stat:
	_def.display_type = value
	return self

func display_format(value: String) -> Stat:
	_def.display_format = value
	return self
