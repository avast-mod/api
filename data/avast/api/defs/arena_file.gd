extends RefCounted

enum Table { SMALL, SCRIPT, ARCHIVE, INSTALLER, SPECIAL, POWERUP }
const ArenaFile := preload("res://avast/api/defs/arena_file.gd")

var id := ""
var _def := {}

func _init(file_id: String, title_text: String = "") -> void:
	id = file_id
	_def.title = title_text if not title_text.is_empty() else file_id

func title(value: String) -> ArenaFile:
	_def.title = value
	return self

func icon(value: Variant) -> ArenaFile:
	_def.icon = value
	return self

func on_open(fn: Callable) -> ArenaFile:
	_def.open = fn
	return self

func table(value: Table) -> ArenaFile:
	_def.table = value
	return self

func weight(value: int) -> ArenaFile:
	_def.weight = value
	return self
