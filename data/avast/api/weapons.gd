extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const Weapon := preload("res://avast/api/defs/weapon.gd")
const WeaponUpgrade := preload("res://avast/api/defs/weapon_upgrade.gd")
const Starter := preload("res://avast/api/lib/starter.gd")

const _WEAPONS := preload("res://resources/upgrades/weapons/weapons_manifest.tres")
const _UPGRADE_MAP := preload("res://resources/upgrades/weapons/weapon_upgrades_map.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: Weapon) -> Ability:
	var id := definition.id
	var def := definition._def
	var clean := _clean(id)
	var base: Ability = null
	if def.has("base"):
		base = find(str(def.base))
		if base == null:
			push_warning("[%s] weapons.add('%s'): unknown base '%s'. See weapons.list()" % [_mod.mod_id, id, def.base])
			return null
	var weapon: Ability = Content.clone(base) if base != null else Ability.new()
	if base == null:
		weapon.type = AbilityUpgrade.Types.WEAPON
		weapon.max_quantity = 1
	Content.apply(_mod, weapon, def, ["id", "base", "controller", "upgrades", "starter"], "weapons.add('%s')" % id)
	weapon.id = "weapon_" + clean

	var controller := Defs.scene(_mod, def.controller) if def.has("controller") else weapon.ability_controller_scene
	if controller == null:
		push_warning("[%s] weapons.add('%s'): needs a 'controller' scene or a 'base' weapon" % [_mod.mod_id, id])
		return null
	weapon.ability_controller_scene = Defs.repack(controller, _mod.path("weapons/%s.tscn" % clean),
		func(root: Node) -> void: root.set("weapon_id", clean))

	var weapon_upgrades: Array = []
	if def.has("upgrades"):
		for entry in def.upgrades:
			var upgrade := _upgrade_from(clean, entry)
			if upgrade != null:
				weapon_upgrades.append(upgrade)
	elif base != null:
		for upgrade: AbilityUpgrade in _map().get(base.id, []):
			var suffix := upgrade.get_resolved_stat_suffix()
			var copy: AbilityUpgrade = upgrade.duplicate()
			copy.id = "upgrade_%s_%s" % [clean, suffix]
			copy.weapon_stat_id = clean
			copy.stat_suffix = suffix
			weapon_upgrades.append(copy)

	Defs.put_by_id(_WEAPONS.items, weapon)
	_map()[weapon.id] = weapon_upgrades
	var um := Game.upgrade_manager()
	if um != null:
		Defs.put_by_id(um.all_weapons, weapon)
		um.weapon_upgrades_map[weapon.id] = weapon_upgrades
		if not weapon in um.current_weapons and not um.weapon_pool.contains_item(weapon):
			um.weapon_pool.add_item(weapon, 10)
	if def.get("starter", true):
		Starter.add_weapon(weapon)
	else:
		Starter.remove_weapon(weapon.id)
	return weapon

func add_upgrade(weapon_id: String, definition: WeaponUpgrade) -> AbilityUpgrade:
	var weapon := find(weapon_id)
	if weapon == null:
		push_warning("[%s] weapons.add_upgrade: unknown weapon '%s'" % [_mod.mod_id, weapon_id])
		return null
	var upgrade := _upgrade_from(_clean(weapon_id), definition)
	if upgrade == null:
		return null
	var list: Array = _map().get(weapon.id, [])
	Defs.put_by_id(list, upgrade)
	_map()[weapon.id] = list
	var um := Game.upgrade_manager()
	if um != null:
		um.weapon_upgrades_map[weapon.id] = list
		if weapon in um.current_weapons and not um.upgrade_pool.contains_item(upgrade):
			um.upgrade_pool.add_item(upgrade, 10)
	return upgrade

func upgrades(weapon_id: String) -> Array:
	return _map().get("weapon_" + _clean(weapon_id), []).duplicate()

func give(id: String) -> bool:
	var weapon := find(id)
	var um := Game.upgrade_manager()
	if weapon == null or um == null or weapon in um.current_weapons:
		return false
	um.apply_weapon(weapon)
	return true

func owned() -> Array[String]:
	var out: Array[String] = []
	var um := Game.upgrade_manager()
	if um != null:
		for weapon: Ability in um.current_weapons:
			out.append(_clean(weapon.id))
	return out

func find(id: String) -> Ability:
	return Defs.find_by_id(_WEAPONS.items, "weapon_" + _clean(id)) as Ability

func has(id: String) -> bool:
	return find(id) != null

func list() -> Array[String]:
	var out: Array[String] = []
	for weapon in _WEAPONS.items:
		out.append(_clean(weapon.id))
	out.sort()
	return out

func _upgrade_from(weapon: String, entry: Variant) -> AbilityUpgrade:
	if entry is AbilityUpgrade:
		return entry
	if entry is String:
		for list in _map().values():
			var found := Defs.find_by_id(list, entry)
			if found != null:
				return found
		push_warning("[%s] unknown weapon upgrade '%s'" % [_mod.mod_id, entry])
		return null
	if not entry is WeaponUpgrade:
		push_warning("[%s] weapon upgrades must be WeaponUpgrade objects, AbilityUpgrade resources or upgrade ids, got %s" % [_mod.mod_id, entry])
		return null
	var stat: String = entry._def.stat
	var upgrade := AbilityUpgrade.new()
	upgrade.type = AbilityUpgrade.Types.WEAPON_UPGRADE
	upgrade.max_quantity = 0
	Content.apply(_mod, upgrade, entry._def, ["id", "type", "weapon_stat_id", "stat_suffix", "stat"], "weapon upgrade '%s'" % stat)
	upgrade.id = "upgrade_%s_%s" % [weapon, stat]
	upgrade.weapon_stat_id = weapon
	upgrade.stat_suffix = stat
	return upgrade

func _map() -> Dictionary:
	return _UPGRADE_MAP.items[0]

static func _clean(id: String) -> String:
	return id.trim_prefix("weapon_")
