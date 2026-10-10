extends RefCounted

const StartItem := preload("res://avast/api/defs/start_item.gd")

var id := ""
var _def := {}

func _init(item_id: String, title_text: String = "") -> void:
	id = item_id
	_def.title = title_text if not title_text.is_empty() else item_id

func title(value: String) -> StartItem:
	_def.title = value
	return self

func icon(value: Variant) -> StartItem:
	_def.icon = value
	return self

func on_open(fn: Callable) -> StartItem:
	_def.open = fn
	return self

func pinned(on: bool = true) -> StartItem:
	_def.pinned = on
	return self

func show_alert(on: bool = true) -> StartItem:
	_def.alert = on
	return self

func window(content: Variant, size: Vector2 = Vector2(360, 240)) -> StartItem:
	_def.window = content
	_def.window_size = size
	return self
