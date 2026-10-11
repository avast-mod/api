extends Node

const API_VERSION := "0.1.1-beta"

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Types := preload("res://avast/api/defs/types.gd")

const Events := preload("res://avast/api/defs/event_names.gd")
const Component := preload("res://avast/api/defs/component.gd")
const Abilities := preload("res://avast/api/defs/abilities.gd")
const Enemy := preload("res://avast/api/defs/enemy.gd")
const Boss := preload("res://avast/api/defs/boss.gd")
const Phase := preload("res://avast/api/defs/phase.gd")
const Wave := preload("res://avast/api/defs/wave.gd")
const Weapon := preload("res://avast/api/defs/weapon.gd")
const WeaponUpgrade := preload("res://avast/api/defs/weapon_upgrade.gd")
const StatUpgrade := preload("res://avast/api/defs/stat_upgrade.gd")
const Stat := preload("res://avast/api/defs/stat.gd")
const PluginDef := preload("res://avast/api/defs/plugin_def.gd")
const DriverDef := preload("res://avast/api/defs/driver_def.gd")
const Protocol := preload("res://avast/api/defs/protocol.gd")
const Policy := preload("res://avast/api/defs/policy.gd")
const ArenaFile := preload("res://avast/api/defs/arena_file.gd")
const DesktopIcon := preload("res://avast/api/defs/desktop_icon.gd")
const StartItem := preload("res://avast/api/defs/start_item.gd")
const CursorClass := preload("res://avast/api/defs/cursor_class.gd")

const Rarity := Types.Rarity
const ModifierType := Types.ModifierType
const WeaponStat := Types.WeaponStat
const DamageType := Types.DamageType
const Corner := Types.Corner
const Currency := Types.Currency

const _Events := preload("res://avast/api/events.gd")
const _Hooks := preload("res://avast/api/hooks.gd")
const _Run := preload("res://avast/api/run.gd")
const _Player := preload("res://avast/api/player.gd")
const _Stats := preload("res://avast/api/stats.gd")
const _Enemies := preload("res://avast/api/enemies.gd")
const _Bosses := preload("res://avast/api/bosses.gd")
const _Waves := preload("res://avast/api/waves.gd")
const _Weapons := preload("res://avast/api/weapons.gd")
const _Upgrades := preload("res://avast/api/upgrades.gd")
const _Plugins := preload("res://avast/api/plugins.gd")
const _Drivers := preload("res://avast/api/drivers.gd")
const _Protocols := preload("res://avast/api/protocols.gd")
const _Policies := preload("res://avast/api/policies.gd")
const _Files := preload("res://avast/api/files.gd")
const _Desktop := preload("res://avast/api/desktop.gd")
const _Windows := preload("res://avast/api/windows.gd")
const _Ui := preload("res://avast/api/ui.gd")
const _Audio := preload("res://avast/api/audio.gd")
const _Appearance := preload("res://avast/api/appearance.gd")
const _Locale := preload("res://avast/api/locale.gd")
const _Save := preload("res://avast/api/save.gd")
const _Mods := preload("res://avast/api/mods.gd")
const _Classes := preload("res://avast/api/classes.gd")
const _Settings := preload("res://avast/api/settings.gd")

var _modules := {}

var mod_id: String:
	get:
		return str(name)

var events: _Events:
	get: return _module(_Events)
var hooks: _Hooks:
	get: return _module(_Hooks)
var run: _Run:
	get: return _module(_Run)
var player: _Player:
	get: return _module(_Player)
var stats: _Stats:
	get: return _module(_Stats)
var enemies: _Enemies:
	get: return _module(_Enemies)
var bosses: _Bosses:
	get: return _module(_Bosses)
var waves: _Waves:
	get: return _module(_Waves)
var weapons: _Weapons:
	get: return _module(_Weapons)
var upgrades: _Upgrades:
	get: return _module(_Upgrades)
var plugins: _Plugins:
	get: return _module(_Plugins)
var drivers: _Drivers:
	get: return _module(_Drivers)
var protocols: _Protocols:
	get: return _module(_Protocols)
var policies: _Policies:
	get: return _module(_Policies)
var files: _Files:
	get: return _module(_Files)
var desktop: _Desktop:
	get: return _module(_Desktop)
var windows: _Windows:
	get: return _module(_Windows)
var ui: _Ui:
	get: return _module(_Ui)
var audio: _Audio:
	get: return _module(_Audio)
var appearance: _Appearance:
	get: return _module(_Appearance)
var locale: _Locale:
	get: return _module(_Locale)
var save: _Save:
	get: return _module(_Save)
var mods: _Mods:
	get: return _module(_Mods)
var classes: _Classes:
	get: return _module(_Classes)
var settings: _Settings:
	get: return _module(_Settings)

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		locale.load_folder()
	elif what == NOTIFICATION_TRANSLATION_CHANGED and _Locale._locale_changed():
		_Events._dispatch(Events.LANGUAGE_CHANGED, [TranslationServer.get_locale()])

func text(key: String, args: Dictionary = {}) -> String:
	return locale.text(key, args)

func _module(script: GDScript) -> RefCounted:
	if not _modules.has(script):
		_modules[script] = script.new(self)
	return _modules[script]

func path(rel: String) -> String:
	if rel.begins_with("res://") or rel.begins_with("user://") or rel.begins_with("uid://"):
		return rel
	return "res://gdpatch/mods/%s/%s" % [mod_id, rel.trim_prefix("/")]

func asset(rel_path: String) -> Resource:
	match rel_path.get_extension().to_lower():
		"png", "jpg", "jpeg", "webp", "bmp", "svg":
			return Defs.texture(self, rel_path)
		"ogg", "wav", "mp3":
			return Defs.sound(self, rel_path)
	var p := path(rel_path)
	return load(p) if ResourceLoader.exists(p) else null

func dir() -> String:
	var gdp := Game.gdpatch()
	return str(gdp.get_mod_directory(mod_id)) if gdp != null else ""

func info(msg: Variant) -> void:
	_log("info", msg)

func warn(msg: Variant) -> void:
	push_warning("[%s] %s" % [mod_id, msg])
	_log("warn", msg)

func error(msg: Variant) -> void:
	push_error("[%s] %s" % [mod_id, msg])
	_log("error", msg)

func _log(level: String, msg: Variant) -> void:
	var text := "[%s] %s" % [mod_id, msg]
	var gdp := Game.gdpatch()
	if gdp != null:
		gdp.log_message(level, text)
	elif level == "info":
		print(text)

func config(section: String, option: String, default_value: Variant = null) -> Variant:
	var gdp := Game.gdpatch()
	var value: Variant = gdp.get_config_option(mod_id, section, option) if gdp != null else null
	return default_value if value == null else value

func set_config(section: String, option: String, value: Variant) -> void:
	var gdp := Game.gdpatch()
	if gdp != null:
		gdp.set_config_option(mod_id, section, option, value)

func save_value(key: String, value: Variant) -> bool:
	return save.set_value(key, value)

func load_value(key: String, default_value: Variant = null) -> Variant:
	return save.get_value(key, default_value)
