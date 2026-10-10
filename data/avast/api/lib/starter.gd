extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")

const SCENE := "res://scenes/static_levels/starter_folder.tscn"
const _DIFF_ICON := "res://scenes/game_object/clickables/difficulty_icon/diff_icon.tscn"
const _CURSOR_ICON := "res://scenes/game_object/clickables/cursor_icon/cursor_icon.tscn"
const _WEAPON_ICON := "res://scenes/game_object/clickables/weapon_icon/weapon_icon.tscn"
const _STD_BUTTON := "res://scenes/ui/standard_button/standard_button.tscn"
const _SECTIONS := {
	"protocols": ["HBoxContainer/VBoxContainer/GridDiff/HBoxContainer", "HBoxContainer/VBoxContainer/HeaderDiff", 5],
	"classes": ["HBoxContainer/VBoxContainer/GridCursor/GridContainer", "HBoxContainer/VBoxContainer/HeaderCursor", 7],
	"weapons": ["HBoxContainer/Weapons/GridWeapons/HBoxContainer", "HBoxContainer/Weapons/HeaderWeapons", 28],
}

static var _protocols := {}
static var _classes := {}
static var _weapons := {}
static var _hooked := false

static func add_protocol(protocol: ProtocolSettings) -> void:
	_protocols[protocol.id] = protocol
	_hook()

static func remove_protocol(id: String) -> void:
	_protocols.erase(id)

static func add_class(player_class: PlayerClass) -> void:
	_classes[player_class.id] = player_class
	_hook()

static func remove_class(id: String) -> void:
	_classes.erase(id)

static func add_weapon(weapon: Ability) -> void:
	_weapons[weapon.id] = weapon
	_hook()

static func remove_weapon(id: String) -> void:
	_weapons.erase(id)

static func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	Game.tree().node_added.connect(func(node: Node) -> void:
		if node.scene_file_path == SCENE:
			node.ready.connect(_fill.bind(node), Object.CONNECT_ONE_SHOT))

static func _fill(folder: Node) -> void:
	_add_icons(folder, "protocols", _protocols.values().map(func(protocol: ProtocolSettings) -> Node:
		var icon: Node = load(_DIFF_ICON).instantiate()
		icon.icon = protocol.icon
		icon.title = protocol.protocol_name
		icon.desc = protocol.description
		icon.protocol = protocol
		return icon))
	_add_icons(folder, "classes", _classes.values().map(func(player_class: PlayerClass) -> Node:
		var icon: Node = load(_CURSOR_ICON).instantiate()
		icon.player_class = player_class
		icon.title = player_class.player_class_name
		icon.desc = player_class.description
		return icon))
	_add_icons(folder, "weapons", _weapons.values().map(func(weapon: Ability) -> Node:
		var icon: Node = load(_WEAPON_ICON).instantiate()
		icon.chosen_weapon = weapon
		return icon))

static func _add_icons(folder: Node, section: String, icons: Array) -> void:
	var paths: Array = _SECTIONS[section]
	var container: Node = folder.get_node_or_null(paths[0])
	if container == null or icons.is_empty():
		return
	for icon in icons:
		_slot(container, icon)
	if paths[2] > 0:
		_pager(folder.get_node_or_null(str(paths[1]) + "/MarginContainer/HBoxContainer"), container, paths[2])

static func _pager(header: Node, container: Node, per_page: int) -> void:
	var slots: Array = container.get_children().filter(func(child: Node) -> bool: return child is Control)
	if header == null or slots.size() <= per_page:
		return
	var pages := ceili(slots.size() / float(per_page))
	var state := {"page": 0}
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	var prev: Button = _arrow("<")
	var label := Label.new()
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var next: Button = _arrow(">")
	for node in [prev, label, next]:
		header.add_child(node)
	var show := func() -> void:
		for i in slots.size():
			var on: bool = i / per_page == state.page
			slots[i].visible = on
			slots[i].process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		label.text = "%d/%d" % [state.page + 1, pages]
		prev.disabled = state.page == 0
		next.disabled = state.page == pages - 1
	prev.clicked.connect(func() -> void:
		state.page = maxi(state.page - 1, 0)
		show.call())
	next.clicked.connect(func() -> void:
		state.page = mini(state.page + 1, pages - 1)
		show.call())
	show.call()

static func _arrow(text: String) -> Button:
	var button: Button = load(_STD_BUTTON).instantiate()
	button.text = text
	button.custom_minimum_size = Vector2(18, 14)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_constant_override("h_separation", 0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box: StyleBox = button.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 0
		box.content_margin_right = 0
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		button.add_theme_stylebox_override(state, box)
	return button

static func _slot(parent: Node, icon: Node) -> void:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(48, 48)
	slot.add_child(icon)
	parent.add_child(slot)
