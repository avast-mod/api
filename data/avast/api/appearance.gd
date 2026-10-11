extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

const _WALLPAPER_DEFINITION := "res://resources/cosmetics/wallpaper_definition.gd"

static var _cursor: Texture2D = null
static var _cursor_hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add_wallpaper(id: String, texture: Variant, display_name: String = "") -> bool:
	var tex := Defs.texture(_mod, texture)
	if tex == null:
		return false
	var def: Resource = load(_WALLPAPER_DEFINITION).new()
	def.id = id
	def.display_name = display_name if not display_name.is_empty() else id + ".jpg"
	def.texture = tex
	def.starter = true
	Game.after_ready("AppearanceManager", func() -> void:
		var am := Game.autoload("AppearanceManager")
		def.number = am.wallpapers.size() + 1
		am.wallpapers[id] = def
		_reapply_profile())
	return true

func add_theme(folder: String) -> String:
	var def: Resource = Game.autoload("AppearanceManager").load_custom_theme(_mod.path(folder))
	if def == null or def.id.is_empty():
		push_warning("[%s] appearance.add_theme: no valid theme.json in '%s'" % [_mod.mod_id, folder])
		return ""
	Game.after_ready("AppearanceManager", func() -> void:
		Game.autoload("AppearanceManager").themes[def.id] = def
		_reapply_profile())
	return def.id

func wallpaper(id: String) -> void:
	Game.after_ready("AppearanceManager", _set_wallpaper.bind(id))

func _set_wallpaper(id: String) -> void:
	var am := Game.autoload("AppearanceManager")
	if not am.wallpapers.has(id):
		push_warning("[%s] unknown wallpaper '%s'. Ids: %s" % [_mod.mod_id, id, am.wallpapers.keys()])
	elif _has_profile() and am.is_wallpaper_owned(id):
		am.set_wallpaper_id(id)
	else:
		am.apply_wallpaper(id)

func theme(id: String) -> void:
	Game.after_ready("AppearanceManager", _set_theme.bind(id))

func _set_theme(id: String) -> void:
	var am := Game.autoload("AppearanceManager")
	if not am.themes.has(id):
		push_warning("[%s] unknown theme '%s'. Ids: %s" % [_mod.mod_id, id, am.themes.keys()])
	elif _has_profile() and am.is_theme_owned(id):
		am.set_theme_id(id)
	else:
		am.apply_theme(id)

func wallpapers() -> Array:
	return Game.autoload("AppearanceManager").wallpapers.keys()

func themes() -> Array:
	return Game.autoload("AppearanceManager").themes.keys()

func cursor(texture: Variant) -> void:
	_cursor = Defs.texture(_mod, texture) if texture != null else null
	if not _cursor_hooked:
		_cursor_hooked = true
		Game.tree().node_added.connect(func(node: Node) -> void:
			if node is Cursor and _cursor != null:
				node.ready.connect(func() -> void: node.apply_cursor_texture(_cursor), Object.CONNECT_ONE_SHOT))
	var current: Node = Game.autoload("GameEvents").active_cursor
	if is_instance_valid(current):
		current.apply_cursor_texture(_cursor if _cursor != null else load("uid://qtcyq70j3mqq"))

static func _reapply_profile() -> void:
	if Game.autoload("SaveManager").active_slot != 0:
		Game.autoload("AppearanceManager").apply_from_profile()

func _has_profile() -> bool:
	return Game.autoload("SaveManager").active_slot != 0
