extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")

static var _translations: Array[Translation] = []
static var _loaded := {}
static var _last_locale := ""

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func text(key: String, args: Dictionary = {}) -> String:
	var found := TranslationServer.translate(key)
	return found.format(args) if not args.is_empty() else found

func has(key: String) -> bool:
	return TranslationServer.translate(key) != key

func add(locale_code: String, entries: Dictionary) -> void:
	var t := Translation.new()
	t.locale = locale_code
	for key in entries:
		t.add_message(str(key), str(entries[key]))
	_translations.append(t)
	Game.after_ready("Localization", func() -> void:
		TranslationServer.add_translation(t)
		var loc := Game.autoload("Localization")
		if not t in loc.runtime_translations:
			loc.runtime_translations.append(t)
		loc.register_locale(locale_code))

func load_folder(folder: String = "lang") -> int:
	var path: String = _mod.dir().path_join(folder)
	if _loaded.has(path) or not DirAccess.dir_exists_absolute(path):
		return 0
	_loaded[path] = true
	var count := 0
	for file in DirAccess.get_files_at(path):
		if file.get_extension().to_lower() == "po":
			add(file.get_basename(), Game.autoload("Localization").parse_po_file(path.path_join(file)))
			count += 1
	return count

func use(locale_code: String) -> void:
	Game.after_ready("Localization", func() -> void: Game.autoload("Localization").set_locale(locale_code))

func current() -> String:
	return TranslationServer.get_locale()

func available() -> Array[String]:
	return Game.autoload("Localization").available_locales

func name_of(locale_code: String) -> String:
	return Game.autoload("Localization").get_display_name(locale_code)

static func _locale_changed() -> bool:
	var now := TranslationServer.get_locale()
	if now == _last_locale:
		return false
	_last_locale = now
	for t in _translations:
		TranslationServer.add_translation(t)
	return true
