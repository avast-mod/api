extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

const Types := preload("res://avast/api/defs/types.gd")
const Stat := preload("res://avast/api/defs/stat.gd")
const _STAT_DEFINITION := "res://resources/stats/stat_definition.gd"

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func value(stat: String) -> float:
	return Game.autoload("StatsManager").final_stats.get(stat, 0.0)

func add(stat: String, amount: float, mode: Types.ModifierType = Types.ModifierType.PERCENT) -> void:
	if _check(stat):
		Game.autoload("StatsManager").add_stat_upgrade(stat, amount, mode)

func buff(stat: String, amount: float, seconds: float, mode: Types.ModifierType = Types.ModifierType.PERCENT) -> void:
	if _check(stat):
		Game.autoload("StatsManager").add_timed_buff(stat, amount, seconds, mode)

func define(definition: Stat) -> void:
	var stat := definition.id
	var def := definition._def
	if stat.is_empty():
		return
	var sd: Resource = load(_STAT_DEFINITION).new()
	sd.id = stat
	sd.display_name = str(def.get("name", stat))
	if def.has("description"):
		sd.description = str(def.description)
	if def.has("icon"):
		sd.icon = Defs.texture(_mod, def.icon)
	if def.has("display_type"):
		sd.display_type = def.display_type
	if def.has("display_format"):
		sd.display_format = def.display_format
	var base := float(def.get("base", 0.0))
	var sm := Game.autoload("StatsManager")
	sm.base_stats[stat] = base
	if not sm.final_stats.has(stat):
		sm.final_stats[stat] = base
	Game.after_ready("StatDatabase", func() -> void: Game.autoload("StatDatabase").stats[stat] = sd)

func has(stat: String) -> bool:
	return Game.autoload("StatsManager").base_stats.has(stat)

func list() -> Array[String]:
	var out: Array[String] = []
	out.assign(Game.autoload("StatsManager").base_stats.keys())
	out.sort()
	return out

func counter(key: String) -> int:
	return int(Game.autoload("StatTracker").get_value(key))

func bump(key: String, amount: int = 1) -> void:
	Game.autoload("StatTracker").bump(key, amount)

func _check(stat: String) -> bool:
	if has(stat):
		return true
	push_warning("[%s] unknown stat '%s'. See stats.list(), or create it with stats.define()" % [_mod.mod_id, stat])
	return false
