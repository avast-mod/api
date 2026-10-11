extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Toml := preload("res://avast/api/lib/toml.gd")
const Version := preload("res://avast/api/lib/version.gd")
const ModInfo := preload("res://avast/api/lib/mod_info.gd")

static var _infos := {}

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func list() -> Array[ModInfo]:
	_load()
	var out: Array[ModInfo] = []
	out.assign(_infos.values())
	out.sort_custom(func(a: ModInfo, b: ModInfo) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	return out

func info(id: String) -> ModInfo:
	_load()
	return _infos.get(id)

func has(id: String) -> bool:
	_load()
	return _infos.has(id)

func problems(id: String) -> Array[String]:
	var mod_info := info(id)
	if mod_info == null:
		return []
	return mod_info.problems(_infos.keys(), _mod.API_VERSION, game_build())

func game_build() -> String:
	var build_info := Game.autoload("BuildInfo")
	var build: Variant = build_info.get("BUILD_TIMESTAMP") if build_info != null else null
	return str(build) if build != null else ""

func root() -> String:
	var gdpatch := Game.gdpatch()
	return str(gdpatch.get_root_directory()) if gdpatch != null else ""

func version_at_least(version: String, minimum: String) -> bool:
	return Version.at_least(version, minimum)

func reload() -> void:
	_infos.clear()
	_load()

static func _load() -> void:
	if not _infos.is_empty():
		return
	var gdpatch := Game.gdpatch()
	if gdpatch == null:
		return
	for entry: Dictionary in gdpatch.get_mods():
		var id := str(entry.get("id", ""))
		if id.is_empty() or id == "gdpatch":
			continue
		var dir: Variant = gdpatch.get_mod_directory(id)
		var info := ModInfo.new()
		info.id = id
		info.dir = str(dir) if dir != null else ""
		var toml_path := info.dir.path_join("gdpatch_mod.toml")
		info.manifest = Toml.parse(FileAccess.get_file_as_string(toml_path)) if FileAccess.file_exists(toml_path) else entry
		var meta: Dictionary = info.manifest.get("meta", {}) if info.manifest.get("meta") is Dictionary else {}
		var avast: Dictionary = info.manifest.get("avast", {}) if info.manifest.get("avast") is Dictionary else {}
		info.name = str(meta.get("name", id))
		info.version = str(meta.get("version", ""))
		info.description = str(meta.get("description", ""))
		info.website = str(meta.get("website", ""))
		info.authors.assign(_strings(meta.get("authors", [])))
		info.tags.assign(_strings(avast.get("tags", [])))
		info.links = avast.get("links", {}) if avast.get("links") is Dictionary else {}
		info.requires_api = str(avast.get("api", ""))
		info.game_builds.assign(_strings(avast.get("game", [])))
		info.dependencies.assign(_strings(avast.get("dependencies", [])))
		info.update = avast.get("update", {}) if avast.get("update") is Dictionary else {}
		_infos[id] = info

static func _strings(v: Variant) -> Array:
	if v is Array:
		return v.map(func(x: Variant) -> String: return str(x))
	return [str(v)] if v is String and not v.is_empty() else []
