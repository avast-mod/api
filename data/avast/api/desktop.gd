extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const DesktopIcon := preload("res://avast/api/defs/desktop_icon.gd")
const StartItem := preload("res://avast/api/defs/start_item.gd")
const Component := preload("res://avast/api/defs/component.gd")

const _ICON_SCENE := "res://scenes/game_object/folder/folder_menu.tscn"
const _ICON_SCRIPT := preload("res://avast/api/ui/desktop_icon.gd")
const _DESKTOP := "DesktopCanvas/Desktop"
const _START_BUTTON := "res://scenes/ui/standard_button/main_menu_button.tscn"
const _ALERT_SCENE := "res://scenes/ui/new_alert.tscn"
const _START_LIST := "DesktopCanvas/Desktop/StartMenu/MarginContainer/VBoxContainer"
const _START_ROW := 33.0
const _START_MAX := 2
const _PROGRAMS_ICON := "res://assets/icons/avzip24.png"
const _SLOTS: Array[Vector2] = [
	Vector2(185, 280), Vector2(185, 340), Vector2(325, 340), Vector2(395, 280), Vector2(395, 340),
	Vector2(465, 160), Vector2(465, 220), Vector2(465, 280), Vector2(465, 340),
	Vector2(535, 160), Vector2(535, 220), Vector2(535, 280), Vector2(535, 340),
]

static var _icons := {}
static var _start_items := {}
static var _hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)

func add_icon(icon: DesktopIcon) -> void:
	_register(icon.id, icon._def, _opener(icon._def))

func add_start_item(item: StartItem) -> void:
	var key := _key(item.id)
	_start_items[key] = {"key": key, "def": item._def, "open": _opener(item._def), "mod": _mod}
	_hook()
	_refresh_start()

func remove_start_item(id: String) -> void:
	_start_items.erase(_key(id))
	_refresh_start()

func show_start_alert(id: String, on: bool = true) -> void:
	var entry: Dictionary = _start_items.get(_key(id), {})
	if entry.is_empty() or bool(entry.def.get("alert", false)) == on:
		return
	entry.def.alert = on
	_refresh_start()

func has_start_alert(id: String) -> bool:
	return bool(_start_items.get(_key(id), {}).get("def", {}).get("alert", false))

func _opener(def: Dictionary) -> Callable:
	if not def.has("window"):
		return def.get("open", Callable())
	var mod := _mod
	return func() -> void: mod.windows.open(def.window, str(def.title), def.window_size)

func remove(id: String) -> void:
	var key := _key(id)
	_icons.erase(key)
	var menu := Game.main_menu()
	if menu != null:
		_free(menu, menu.get_node(_DESKTOP).get_node_or_null(key))

func find(title: String) -> Node2D:
	var menu := Game.main_menu()
	if menu == null:
		return null
	for icon in menu.get_node(_DESKTOP).get_children():
		if icon is MenuClickable and (icon.name == title or icon._folder_name == title or icon.localized_folder_name() == title):
			return icon
	return null

func _register(id: String, def: Dictionary, on_open: Callable) -> void:
	var key := _key(id)
	_icons[key] = {"def": def, "open": on_open, "mod": _mod}
	_hook()
	var menu := Game.main_menu()
	if menu != null and menu.is_node_ready():
		_place(menu, key)

static func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	Game.on_scene(Game.MAIN_MENU, Game.gdpatch() if Game.gdpatch() != null else Game.tree().root, _place_all)

func _key(id: String) -> String:
	return "AVaSt_%s_%s" % [_mod.mod_id, id]

static func _place_all(menu: Node) -> void:
	var keys := _icons.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return _icons[a].def.has("position") and not _icons[b].def.has("position"))
	for key in keys:
		_place(menu, key)
	_layout_start(menu)

static func _place(menu: Node, key: String) -> void:
	var entry: Dictionary = _icons[key]
	if not is_instance_valid(entry.mod):
		return
	var desktop: Node = menu.get_node(_DESKTOP)
	_free(menu, desktop.get_node_or_null(key))
	var icon: Node2D = load(_ICON_SCENE).instantiate()
	icon.set_script(_ICON_SCRIPT)
	icon.name = key
	icon._folder_name = str(entry.def.get("title", key))
	icon._tooltip_key = "CLICKABLE.double_click_open"
	icon.on_open = entry.open
	icon.position = entry.def.get("position", _free_slot(desktop))
	var tex := Defs.texture(entry.mod, entry.def.get("icon"))
	if tex != null:
		var sprite: Sprite2D = icon.get_node("Sprite2D")
		sprite.texture = tex
		sprite.scale = Vector2.ONE * 32.0 / maxf(tex.get_width(), tex.get_height())
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	desktop.add_child(icon)
	menu.links.append(icon)

static func _refresh_start() -> void:
	var menu := Game.main_menu()
	if menu != null and menu.is_node_ready():
		_layout_start(menu)

static func _layout_start(menu: Node) -> void:
	var list: Node = menu.get_node(_START_LIST)
	for button in list.get_children():
		if button.name.begins_with("AVaSt_"):
			menu.start_menu_buttons.erase(button)
			list.remove_child(button)
			button.queue_free()
	menu.start_menu.offset_top += menu.start_menu.get_meta(&"avast_rows", 0) * _START_ROW
	var entries := _start_items.values().filter(func(e: Dictionary) -> bool: return is_instance_valid(e.mod))
	var pinned := entries.filter(func(e: Dictionary) -> bool: return e.def.get("pinned", false))
	var others := entries.filter(func(e: Dictionary) -> bool: return not e.def.get("pinned", false))
	if entries.size() > _START_MAX and others.size() > 1:
		var alert := others.any(func(e: Dictionary) -> bool: return e.def.get("alert", false))
		others = [{"key": "AVaSt_programs", "def": {"title": "Programs", "icon": _PROGRAMS_ICON, "alert": alert}, "open": _programs.bind(others), "mod": others[0].mod}]
	entries = pinned + others
	for entry: Dictionary in entries:
		var button: StandardButton = load(_START_BUTTON).instantiate()
		button.name = entry.key
		button.process_mode = Node.PROCESS_MODE_INHERIT
		button.focus_mode = Control.FOCUS_CLICK
		button.text = str(entry.def.title)
		button.icon = Defs.texture(entry.mod, entry.def.get("icon"))
		if entry.open.is_valid():
			button.clicked.connect(entry.open)
		if entry.def.get("alert", false):
			_add_alert(button)
		list.add_child(button)
		list.move_child(button, menu.settings_button.get_index())
		menu.start_menu_buttons.append(button)
	menu.start_menu.set_meta(&"avast_rows", entries.size())
	menu.start_menu.offset_top -= entries.size() * _START_ROW

static func _add_alert(button: Control) -> void:
	var alert: Control = load(_ALERT_SCENE).instantiate()
	alert.name = "AVaStAlert"
	alert.set("large", true)
	alert.anchor_left = 1.0
	alert.anchor_top = 0.5
	alert.anchor_right = 1.0
	alert.anchor_bottom = 0.5
	alert.offset_left = -24.0
	alert.offset_top = -8.0
	alert.offset_right = -8.0
	alert.offset_bottom = 8.0
	alert.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	alert.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.add_child(alert)

static func _programs(entries: Array) -> void:
	var windows: RefCounted = entries[0].mod.windows
	var holder := {}
	var buttons := entries.map(func(e: Dictionary) -> Component.Item:
		return Component.button(str(e.def.title), func() -> void:
			if e.open.is_valid():
				e.open.call()
			windows.close(holder.window)))
	holder.window = windows.form("Programs", buttons, Vector2(220, 26 * entries.size() + 20))

static func _free(menu: Node, icon: Node) -> void:
	if icon == null:
		return
	menu.links.erase(icon)
	icon.get_parent().remove_child(icon)
	icon.queue_free()

static func _free_slot(desktop: Node) -> Vector2:
	var taken: Array[Vector2] = []
	for child in desktop.get_children():
		if child is MenuClickable:
			taken.append(child.position)
	for slot in _SLOTS:
		if not taken.any(func(p: Vector2) -> bool: return p.distance_to(slot) < 30.0):
			return slot
	return _SLOTS.back()

static func _release() -> void:
	_icons.clear()
	_start_items.clear()
