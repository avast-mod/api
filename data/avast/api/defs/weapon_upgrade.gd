extends RefCounted

const Types := preload("res://avast/api/defs/types.gd")
const WeaponUpgrade := preload("res://avast/api/defs/weapon_upgrade.gd")

var id := ""
var _def := {}

func _init(weapon_stat: Types.WeaponStat) -> void:
	_def.stat = Types.WEAPON_STATS[weapon_stat]

func name(value: String) -> WeaponUpgrade:
	_def.name = value
	return self

func description(value: String) -> WeaponUpgrade:
	_def.description = value
	return self

func icon(value: Variant) -> WeaponUpgrade:
	_def.icon = value
	return self

func rarity_values(common: float, uncommon: float, rare: float, epic: float, legendary: float) -> WeaponUpgrade:
	_def.rarity_values = [common, uncommon, rare, epic, legendary]
	return self

func max_quantity(value: int) -> WeaponUpgrade:
	_def.max_quantity = value
	return self

func field(property: String, value: Variant) -> WeaponUpgrade:
	_def[property] = value
	return self
