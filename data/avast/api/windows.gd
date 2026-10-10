extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Dialog := preload("res://avast/api/ui/dialog_window.gd")
const Form := preload("res://avast/api/ui/form.gd")
const Component := preload("res://avast/api/defs/component.gd")

const _WINDOW := "res://scenes/ui/Window/basic_window.tscn"
const _STD_BUTTON := "res://scenes/ui/standard_button/standard_button.tscn"
const _INI_WINDOW := "res://scenes/game_object/clickables/inifile/ini_window.tscn"
const _MENU_FLAGS: Array[String] = [
	"meta_menu_open", "settings_menu_open", "stats_menu_open", "personalise_menu_open",
	"vapor_store_open", "features_store_open", "credits_menu_open",
]

static var _open: Array[Control] = []

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func open(content: Variant, title: String = "", size: Vector2 = Vector2(360, 240), on_close: Callable = Callable(), padding: int = 10) -> Control:
	var menu := Game.main_menu()
	if menu == null:
		push_warning("[%s] windows only open on the desktop. Use windows.notice() during runs." % _mod.mod_id)
		return null
	var body := _build(content)
	if body == null:
		push_warning("[%s] windows.open: can't build a Control from %s" % [_mod.mod_id, content])
		return null

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var window: PanelContainer = load(_WINDOW).instantiate()
	window.custom_minimum_size = size
	window.set_anchors_preset(Control.PRESET_CENTER)
	window.offset_left = -size.x / 2
	window.offset_top = -size.y / 2
	window.offset_right = size.x / 2
	window.offset_bottom = size.y / 2
	root.add_child(window)
	for path in ["PanelContainer", "VBoxContainer", "MarginContainer/HBoxContainer/Min", "MarginContainer/HBoxContainer/Max"]:
		window.get_node(path).visible = false
	window.get_node("MarginContainer2/Label").text = title

	var background := ColorRect.new()
	background.color = Color(0.9490196, 0.9411765, 0.8509804)
	background.add_to_group(&"theme_window_body")
	window.add_child(background)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding)
	window.add_child(margin)
	margin.add_child(body)

	var close_button: Button = load(_STD_BUTTON).instantiate()
	close_button.set_anchors_preset(Control.PRESET_CENTER)
	close_button.offset_left = -9
	close_button.offset_top = -12
	close_button.offset_right = 9
	close_button.offset_bottom = 12
	for state in ["normal", "pressed", "hover", "hover_pressed", "disabled", "focus"]:
		close_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close_button.text = ""
	close_button.custom_theme = true
	close_button.clicked.connect(close.bind(root))
	window.get_node("MarginContainer/HBoxContainer/Close").add_child(close_button)

	for signal_name in ["close", "closed"]:
		if body.has_signal(signal_name):
			body.connect(signal_name, func(_a = null) -> void: close(root))
	if on_close.is_valid():
		root.set_meta(&"on_close", on_close)
	root.add_child(_EscapeListener.new(_escape.bind(root), _guard.bind(root)))

	_prune()
	root.z_index = (_open.size() + 1) * 10
	_open.append(root)
	menu.get_node("DesktopCanvas/DesktopCenter").add_child(root)
	if _open.size() == 1:
		menu.goto_centre()
	return root

func close(window: Control) -> void:
	_close(window)

func popup(title: String, text: String, on_close: Callable = Callable(), icon: Variant = null, ok_text: String = "OK", size: Vector2 = Vector2(300, 140)) -> Control:
	var dialog := Dialog.new(text, Defs.texture(_mod, icon), [ok_text])
	dialog.closed.connect(func(_ok: bool) -> void: _close(dialog.get_meta(&"window")))
	var window := open(dialog, title, size, on_close)
	if window != null:
		dialog.set_meta(&"window", window)
	return window

func confirm(title: String, text: String, on_yes: Callable, on_no: Callable = Callable(), icon: Variant = null, yes_text: String = "Yes", no_text: String = "No", size: Vector2 = Vector2(320, 140)) -> Control:
	var answer := {"yes": false}
	var dialog := Dialog.new(text, Defs.texture(_mod, icon), [yes_text, no_text])
	dialog.closed.connect(func(yes: bool) -> void:
		answer.yes = yes
		_close(dialog.get_meta(&"window")))
	var on_close := func() -> void:
		var fn: Callable = on_yes if answer.yes else on_no
		if fn.is_valid():
			fn.call()
	var window := open(dialog, title, size, on_close)
	if window != null:
		dialog.set_meta(&"window", window)
	return window

func form(title: String, components: Array, size: Vector2 = Vector2(320, 220), on_close: Callable = Callable()) -> Control:
	var body := Form.new()
	body.mod = _mod
	for component in components:
		if component is Component.Item or component is Control:
			body.add_item(component)
		else:
			push_warning("[%s] windows.form: use Component.label(), Component.checkbox() and the like, got %s" % [_mod.mod_id, component])
	return open(body, title, size, on_close)

func notice(title: String, text: String, seconds: float = 2.5) -> void:
	if Game.main_menu() != null:
		popup(title, text)
		return
	var events := Game.autoload("GameEvents")
	if not Game.in_run() or events.get_windows_layer() == null:
		return
	var window: Control = load(_INI_WINDOW).instantiate()
	window.set_script(null)
	window.get_node("Panel/MarginContainer2/Label").text = title
	var column := window.get_node("Panel/MarginContainer3/MarginContainer/VBoxContainer")
	column.get_node("TopText").text = text
	column.get_node("BottomText").hide()
	column.get_node("MarginContainer").hide()
	window.scale = Vector2.ZERO
	events.spawn_corner_window(window)
	var tween := window.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(window, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(seconds)
	tween.tween_property(window, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(window.queue_free)

func _build(content: Variant) -> Control:
	if content is Callable:
		return content.call()
	if content is Control:
		return content
	var res: Variant = content
	if content is String:
		res = Defs.scene(_mod, content) if content.ends_with(".tscn") else Defs.script(_mod, content)
	if res is PackedScene:
		return res.instantiate()
	if res is Script:
		return res.new()
	return null

static func _close(window: Control) -> void:
	if not is_instance_valid(window) or window.has_meta(&"closing"):
		return
	window.set_meta(&"closing", true)
	_open.erase(window)
	if window.has_meta(&"on_close") and window.get_meta(&"on_close").is_valid():
		window.get_meta(&"on_close").call()
	window.queue_free()
	var menu := Game.main_menu()
	if menu != null and _open.is_empty() and not _MENU_FLAGS.any(func(flag: String) -> bool: return menu.get(flag)):
		menu.go_back()

static func _prune() -> void:
	_open.assign(_open.filter(func(w: Variant) -> bool: return is_instance_valid(w)))

static func _escape(window: Control) -> bool:
	_prune()
	if _open.is_empty() or _open.back() != window:
		return false
	_close(window)
	return true

static func _guard(window: Control) -> void:
	_prune()
	var blocked: bool = not _open.is_empty() and _open.back() != window
	if not blocked and not window.has_meta(&"blocked"):
		return
	for button: Node in window.find_children("*", "StandardButton", true, false):
		if blocked and not button.has_meta(&"allow_click"):
			button.set_meta(&"allow_click", button.allow_click)
			button.allow_click = false
		elif not blocked and button.has_meta(&"allow_click"):
			button.allow_click = button.get_meta(&"allow_click")
			button.remove_meta(&"allow_click")
	if blocked:
		window.set_meta(&"blocked", true)
	else:
		window.remove_meta(&"blocked")

class _EscapeListener extends Node:
	var _handler: Callable
	var _guard: Callable

	func _init(handler: Callable, guard: Callable) -> void:
		_handler = handler
		_guard = guard
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(_delta: float) -> void:
		_guard.call()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("close") and _handler.call():
			get_viewport().set_input_as_handled()
