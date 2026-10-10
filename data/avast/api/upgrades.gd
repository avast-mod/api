extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const Types := preload("res://avast/api/defs/types.gd")
const StatUpgrade := preload("res://avast/api/defs/stat_upgrade.gd")

const _PLAYER_UPGRADES := preload("res://resources/upgrades/player/player_upgrades_manifest.tres")
const _WEAPON_UPGRADES := preload("res://resources/upgrades/weapons/weapon_upgrades_map.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: StatUpgrade) -> AbilityUpgrade:
	var stat := definition.id
	var def := definition._def
	var id := _stat_id(stat)
	if not Game.autoload("StatsManager").base_stats.has(id):
		push_warning("[%s] upgrades.add: '%s' is not a stat. See stats.list(), or create it with stats.define()" % [_mod.mod_id, stat])
		return null
	var existing := find(id)
	var upgrade: AbilityUpgrade = Content.clone(existing) if existing != null else AbilityUpgrade.new()
	if existing == null:
		upgrade.max_quantity = 0
	Content.apply(_mod, upgrade, def, ["id", "type"], "upgrades.add('%s')" % stat)
	upgrade.id = id
	upgrade.type = AbilityUpgrade.Types.PLAYER_STAT

	Defs.put_by_id(_PLAYER_UPGRADES.items, upgrade)
	var um := Game.upgrade_manager()
	if um != null:
		Defs.put_by_id(um.all_player_upgrades, upgrade)
		if not um.upgrade_pool.contains_item(upgrade):
			um.upgrade_pool.add_item(upgrade, 5)
	return upgrade

func give(id: String, rarity: Types.Rarity = Types.Rarity.COMMON) -> bool:
	var upgrade := find(id)
	var um := Game.upgrade_manager()
	if upgrade == null or um == null:
		return false
	upgrade.rarity = int(rarity) as AbilityUpgrade.Raritys
	um.apply_upgrade(upgrade)
	return true

func find(id: String) -> AbilityUpgrade:
	var found := Defs.find_by_id(_PLAYER_UPGRADES.items, _stat_id(id))
	if found == null:
		for list in _WEAPON_UPGRADES.items[0].values():
			found = Defs.find_by_id(list, id)
			if found != null:
				break
	return found as AbilityUpgrade

func has(id: String) -> bool:
	return find(id) != null

func list() -> Array[String]:
	var out: Array[String] = []
	for upgrade in _PLAYER_UPGRADES.items:
		out.append(upgrade.id)
	out.sort()
	return out

func _stat_id(stat: String) -> String:
	var stats: Dictionary = Game.autoload("StatsManager").base_stats
	if not stats.has(stat) and stats.has("upgrade_player_" + stat):
		return "upgrade_player_" + stat
	return stat
