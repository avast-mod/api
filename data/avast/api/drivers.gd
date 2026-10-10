extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const DriverDef := preload("res://avast/api/defs/driver_def.gd")

const _DRIVERS := preload("res://resources/drivers/drivers_manifest.tres")
const _WEAPON_DRIVERS := preload("res://resources/drivers/weapon_drivers_map.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: DriverDef) -> DriverDefinition:
	var id := definition.id
	var def := definition._def
	var base: DriverDefinition = null
	if def.has("base"):
		base = find(str(def.base))
		if base == null:
			push_warning("[%s] drivers.add('%s'): unknown base '%s'. See drivers.list()" % [_mod.mod_id, id, def.base])
			return null
	var driver: DriverDefinition = Content.clone(base) if base != null else DriverDefinition.new()
	Content.apply(_mod, driver, def, ["id", "base", "weapon", "script", "modifiers"], "drivers.add('%s')" % id)
	driver.id = id
	if def.has("weapon"):
		driver.weapon_id = str(def.weapon).trim_prefix("weapon_")
	if def.has("modifiers"):
		var modifiers: Array[DriverModifier] = []
		for m in def.modifiers:
			var modifier := _modifier(m)
			if modifier != null:
				modifiers.append(modifier)
		driver.modifiers = modifiers
	if def.has("script"):
		driver.driver_scene = _scene_for(def.script, "drivers/%s.tscn" % id)
		if driver.driver_scene == null:
			return null

	Defs.put_by_id(_DRIVERS.items, driver)
	var map: Dictionary = _WEAPON_DRIVERS.items[0]
	for key in map:
		map[key] = map[key].filter(func(d: DriverDefinition) -> bool: return d.id != id)
	if driver.weapon_id.is_empty():
		for key in map:
			map[key].append(driver)
	else:
		var key := "weapon_" + driver.weapon_id
		if not map.has(key):
			map[key] = []
		map[key].append(driver)
	var um := Game.upgrade_manager()
	if um != null:
		Defs.put_by_id(um.all_drivers, driver)
	return driver

func give(id: String, weapon_id: String) -> bool:
	var driver := find(id)
	var um := Game.upgrade_manager()
	if driver == null or um == null:
		return false
	um.apply_driver(driver, weapon_id.trim_prefix("weapon_"))
	return true

func find(id: String) -> DriverDefinition:
	return Defs.find_by_id(_DRIVERS.items, id) as DriverDefinition

func has(id: String) -> bool:
	return find(id) != null

func list(weapon_id: String = "") -> Array[String]:
	var out: Array[String] = []
	var source: Array = _DRIVERS.items
	if not weapon_id.is_empty():
		source = _WEAPON_DRIVERS.items[0].get("weapon_" + weapon_id.trim_prefix("weapon_"), [])
	for driver in source:
		out.append(driver.id)
	out.sort()
	return out

func _modifier(m: Dictionary) -> DriverModifier:
	var modifier := DriverModifier.new()
	modifier.stat_name = m.stat
	modifier.value = float(m.value)
	modifier.type = int(m.mode)
	return modifier

func _scene_for(script_path: Variant, rel: String) -> PackedScene:
	var script := Defs.script(_mod, script_path)
	if script == null:
		return null
	var node := Node.new()
	node.set_script(script)
	if not node is Driver:
		push_warning("[%s] driver script '%s' must extend Driver" % [_mod.mod_id, script_path])
		node.free()
		return null
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	scene.take_over_path(_mod.path(rel))
	return scene
