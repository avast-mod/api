extends RefCounted

const Types := preload("res://avast/api/defs/types.gd")
const DriverDef := preload("res://avast/api/defs/driver_def.gd")

var id := ""
var _def := {}

func _init(driver_id: String, base_id: String = "") -> void:
	id = driver_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> DriverDef:
	_def.base = base_id
	return self

func for_weapon(weapon_id: String) -> DriverDef:
	_def.weapon = weapon_id
	return self

func modifier(stat: Types.WeaponStat, value: float, mode: Types.ModifierType = Types.ModifierType.PERCENT) -> DriverDef:
	if not _def.has("modifiers"):
		_def.modifiers = []
	_def.modifiers.append({"stat": Types.WEAPON_STATS[stat], "value": value, "mode": mode})
	return self

func behavior(script_or_path: Variant) -> DriverDef:
	_def.script = script_or_path
	return self

func name(value: String) -> DriverDef:
	_def.name = value
	return self

func description(value: String) -> DriverDef:
	_def.description = value
	return self

func icon(value: Variant) -> DriverDef:
	_def.icon = value
	return self

func damage_type(value: Types.DamageType) -> DriverDef:
	_def.override_damage_type = true
	_def.damage_type = value
	return self

func controller_flag(value: String) -> DriverDef:
	_def.controller_flag = value
	return self

func field(property: String, value: Variant) -> DriverDef:
	_def[property] = value
	return self
