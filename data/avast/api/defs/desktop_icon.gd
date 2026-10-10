extends RefCounted

const DesktopIcon := preload("res://avast/api/defs/desktop_icon.gd")

var id := ""
var _def := {}

func _init(icon_id: String, title_text: String = "") -> void:
	id = icon_id
	_def.title = title_text if not title_text.is_empty() else icon_id

func title(value: String) -> DesktopIcon:
	_def.title = value
	return self

func icon(value: Variant) -> DesktopIcon:
	_def.icon = value
	return self

func on_open(fn: Callable) -> DesktopIcon:
	_def.open = fn
	return self

func window(content: Variant, size: Vector2 = Vector2(360, 240)) -> DesktopIcon:
	_def.window = content
	_def.window_size = size
	return self

func at(position: Vector2) -> DesktopIcon:
	_def.position = position
	return self
