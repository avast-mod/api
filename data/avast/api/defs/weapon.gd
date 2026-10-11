extends RefCounted

const Weapon := preload("res://avast/api/defs/weapon.gd")

var id := ""
var _def := {}

func _init(weapon_id: String, base_id: String = "") -> void:
	id = weapon_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> Weapon:
	_def.base = base_id
	return self

func name(value: String) -> Weapon:
	_def.name = value
	return self

func description(value: String) -> Weapon:
	_def.description = value
	return self

func icon(value: Variant) -> Weapon:
	_def.icon = value
	return self

func secondary_icon(value: Variant) -> Weapon:
	_def.secondary_icon = value
	return self

func controller(value: Variant) -> Weapon:
	_def.controller = value
	return self

func upgrade(value: Variant) -> Weapon:
	if not _def.has("upgrades"):
		_def.upgrades = []
	_def.upgrades.append(value)
	return self

func max_quantity(value: int) -> Weapon:
	_def.max_quantity = value
	return self

func starter(on: bool = true) -> Weapon:
	_def.starter = on
	return self

func field(property: String, value: Variant) -> Weapon:
	_def[property] = value
	return self
