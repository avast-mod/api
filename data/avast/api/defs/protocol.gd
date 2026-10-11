extends RefCounted

const Protocol := preload("res://avast/api/defs/protocol.gd")

var id := ""
var _def := {}

func _init(protocol_id: String, base_id: String = "") -> void:
	id = protocol_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> Protocol:
	_def.base = base_id
	return self

func name(value: String) -> Protocol:
	_def.name = value
	return self

func description(value: String) -> Protocol:
	_def.description = value
	return self

func icon(value: Variant) -> Protocol:
	_def.icon = value
	return self

func enemy_movement_speed_scale(value: float) -> Protocol:
	_def.enemy_movement_speed_scale = value
	return self

func enemy_damage_scale(value: float) -> Protocol:
	_def.enemy_damage_scale = value
	return self

func enemy_health_scale(value: float) -> Protocol:
	_def.enemy_health_scale = value
	return self

func spawn_amount_scale(value: float) -> Protocol:
	_def.spawn_amount_scale = value
	return self

func void_damage_scale(value: int) -> Protocol:
	_def.void_damage_scale = value
	return self

func void_lag_stacks(value: float) -> Protocol:
	_def.void_lag_stacks = value
	return self

func beanz_amount_scale(value: int) -> Protocol:
	_def.beanz_amount_scale = value
	return self

func score_scale(value: int) -> Protocol:
	_def.score_scale = value
	return self

func in_starter(on: bool = true) -> Protocol:
	_def.starter = on
	return self

func field(property: String, value: Variant) -> Protocol:
	_def[property] = value
	return self
