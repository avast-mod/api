extends RefCounted

const Version := preload("res://avast/api/lib/version.gd")

var id := ""
var name := ""
var version := ""
var authors: Array[String] = []
var description := ""
var website := ""
var dir := ""
var tags: Array[String] = []
var links := {}
var requires_api := ""
var game_builds: Array[String] = []
var dependencies: Array[String] = []
var update := {}
var manifest := {}

var _cache := {}

func icon() -> Texture2D:
	return _image("icon", "icon.png")

func banner() -> Texture2D:
	return _image("banner", "banner.png")

func screenshots() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for file in _avast().get("screenshots", []):
		var tex := _load_image(_file(str(file)))
		if tex != null:
			out.append(tex)
	return out

func readme() -> String:
	return _text("readme", "README.md")

func changelog() -> String:
	return _text("changelog", "CHANGELOG.md")

func title() -> String:
	return _translated("name", name)

func summary() -> String:
	return _translated("description", description)

func authors_text() -> String:
	if authors.size() <= 1:
		return "" if authors.is_empty() else authors[0]
	return ", ".join(authors.slice(0, -1)) + " and " + authors[-1]

func is_loaded() -> bool:
	var base := "res://gdpatch/mods/%s/mod." % id
	var has_script := FileAccess.file_exists(base + "gd") or FileAccess.file_exists(base + "gdc")
	if not has_script and not FileAccess.file_exists(base + "tscn"):
		return true
	var gdpatch: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GDPatch")
	var node: Node = gdpatch.mod_instances.get(id) if gdpatch != null else null
	return node != null and (node.get_script() != null or not has_script)

func problems(installed_ids: Array, api_version: String, game_build: String) -> Array[String]:
	var out: Array[String] = []
	if not is_loaded():
		out.append("Failed to load. The error is in GDPatch/output.log.")
	if not requires_api.is_empty() and not Version.at_least(api_version, requires_api):
		out.append("Needs AVaSt API %s or newer, %s is installed." % [requires_api, api_version])
	for dep in dependencies:
		if not dep in installed_ids:
			out.append("Needs the mod '%s', which isn't installed." % dep)
	if not game_builds.is_empty() and not game_build in game_builds:
		out.append("Made for game build %s, this is build %s." % [", ".join(game_builds), game_build])
	return out

func _avast() -> Dictionary:
	var avast: Variant = manifest.get("avast", {})
	return avast if avast is Dictionary else {}

func _file(rel: String) -> String:
	return dir.path_join(rel) if not dir.is_empty() and not rel.is_empty() else ""

func _image(key: String, fallback: String) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = _load_image(_file(str(_avast().get(key, fallback))))
	return _cache[key]

func _text(key: String, fallback: String) -> String:
	var locale := TranslationServer.get_locale()
	var cache_key := key + ":" + locale
	if not _cache.has(cache_key):
		var path := _file(str(_avast().get(key, fallback)))
		var base := path.get_basename()
		var ext := path.get_extension()
		for candidate in ["%s.%s.%s" % [base, locale, ext], "%s.%s.%s" % [base, locale.get_slice("_", 0), ext], path]:
			if FileAccess.file_exists(candidate):
				_cache[cache_key] = FileAccess.get_file_as_string(candidate)
				break
		if not _cache.has(cache_key):
			_cache[cache_key] = ""
	return _cache[cache_key]

func _translated(key: String, fallback: String) -> String:
	var full := "MOD.%s.%s" % [id, key]
	var found := TranslationServer.translate(full)
	return fallback if found == full else found

static func _load_image(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null and not img.is_empty() else null
