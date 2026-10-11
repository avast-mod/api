extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const PluginDef := preload("res://avast/api/defs/plugin_def.gd")

const _PLUGINS := preload("res://resources/plugins/plugins_manifest.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: PluginDef) -> PluginDefinition:
	var id := definition.id
	var def := definition._def
	var base: PluginDefinition = null
	if def.has("base"):
		base = find(str(def.base))
		if base == null:
			push_warning("[%s] plugins.add('%s'): unknown base '%s'. See plugins.list()" % [_mod.mod_id, id, def.base])
			return null
	var plugin: PluginDefinition = Content.clone(base) if base != null else PluginDefinition.new()
	Content.apply(_mod, plugin, def, ["id", "base", "script"], "plugins.add('%s')" % id)
	plugin.id = id
	if def.has("script"):
		plugin.plugin_scene = _scene_for(def.script, "plugins/%s.tscn" % id)
	if not _is_valid(plugin.plugin_scene):
		push_warning("[%s] plugins.add('%s'): needs behavior() with a script extending Plugin, or a base plugin" % [_mod.mod_id, id])
		return null

	Defs.put_by_id(_PLUGINS.items, plugin)
	Game.autoload("UnlockManager").plugins_by_id[id] = plugin
	var um := Game.upgrade_manager()
	if um != null:
		Defs.put_by_id(um.all_plugins, plugin)
		if not um.plugin_pool.contains_item(plugin):
			um.plugin_pool.add_item(plugin, 10)
	return plugin

func give(id: String) -> bool:
	var plugin := find(id)
	var um := Game.upgrade_manager()
	if plugin == null or um == null:
		return false
	um.apply_plugin(plugin)
	return true

func owned() -> Array[String]:
	var out: Array[String] = []
	var um := Game.upgrade_manager()
	if um != null:
		out.assign(um.current_plugins.keys())
	return out

func find(id: String) -> PluginDefinition:
	return Defs.find_by_id(_PLUGINS.items, id) as PluginDefinition

func has(id: String) -> bool:
	return find(id) != null

func list() -> Array[String]:
	var out: Array[String] = []
	for plugin in _PLUGINS.items:
		out.append(plugin.id)
	out.sort()
	return out

func _scene_for(script_path: Variant, rel: String) -> PackedScene:
	var script := Defs.script(_mod, script_path)
	if script == null:
		return null
	var node := Node.new()
	node.set_script(script)
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	scene.take_over_path(_mod.path(rel))
	return scene

static func _is_valid(scene: PackedScene) -> bool:
	if scene == null:
		return false
	var root := scene.instantiate()
	var ok := root is Plugin
	root.free()
	return ok
