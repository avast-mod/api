extends RefCounted

const Types := preload("res://avast/api/defs/types.gd")
const StatUpgrade := preload("res://avast/api/defs/stat_upgrade.gd")

var id := ""
var _def := {}

func _init(stat_id: String) -> void:
	id = stat_id

func name(value: String) -> StatUpgrade:
	_def.name = value
	return self

func description(value: String) -> StatUpgrade:
	_def.description = value
	return self

func icon(value: Variant) -> StatUpgrade:
	_def.icon = value
	return self

func modifier_type(value: Types.ModifierType) -> StatUpgrade:
	_def.modifier_type = value
	return self

func rarity_values(common: float, uncommon: float, rare: float, epic: float, legendary: float) -> StatUpgrade:
	_def.rarity_values = [common, uncommon, rare, epic, legendary]
	return self

func max_quantity(value: int) -> StatUpgrade:
	_def.max_quantity = value
	return self

func field(property: String, value: Variant) -> StatUpgrade:
	_def[property] = value
	return self
