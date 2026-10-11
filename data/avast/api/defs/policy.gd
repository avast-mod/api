extends RefCounted

const Policy := preload("res://avast/api/defs/policy.gd")

var id := ""
var _def := {}

func _init(policy_id: String, base_id: String = "") -> void:
	id = policy_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> Policy:
	_def.base = base_id
	return self

func name(value: String) -> Policy:
	_def.name = value
	return self

func description(value: String) -> Policy:
	_def.description = value
	return self

func icon(value: Variant) -> Policy:
	_def.icon = value
	return self

func enemy_movement_multiplier(value: float) -> Policy:
	_def.enemy_movement_multiplier = value
	return self

func enemy_damage_multiplier(value: float) -> Policy:
	_def.enemy_damage_multiplier = value
	return self

func enemy_health_multiplier(value: float) -> Policy:
	_def.enemy_health_multiplier = value
	return self

func spawn_amount_multiplier(value: float) -> Policy:
	_def.spawn_amount_multiplier = value
	return self

func void_damage_multiplier(value: float) -> Policy:
	_def.void_damage_multiplier = value
	return self

func void_lag_multiplier(value: float) -> Policy:
	_def.void_lag_multiplier = value
	return self

func round_duration_multiplier(value: float) -> Policy:
	_def.round_duration_multiplier = value
	return self

func fail_timer_multiplier(value: float) -> Policy:
	_def.fail_timer_multiplier = value
	return self

func reward_multiplier(value: float) -> Policy:
	_def.reward_multiplier = value
	return self

func starting_health_fraction(value: float) -> Policy:
	_def.starting_health_fraction = value
	return self

func disable_weapon_picks(on: bool = true) -> Policy:
	_def.disable_weapon_picks = on
	return self

func disable_keygens(on: bool = true) -> Policy:
	_def.disable_keygens = on
	return self

func disable_rerolls(on: bool = true) -> Policy:
	_def.disable_rerolls = on
	return self

func skip_starter_weapon(on: bool = true) -> Policy:
	_def.skip_starter_weapon = on
	return self

func void_instant_kill(on: bool = true) -> Policy:
	_def.void_instant_kill = on
	return self

func disable_battle_files(on: bool = true) -> Policy:
	_def.disable_battle_files = on
	return self

func spam_on_window_close(on: bool = true) -> Policy:
	_def.spam_on_window_close = on
	return self

func is_domain(on: bool = true) -> Policy:
	_def.is_domain = on
	return self

func field(property: String, value: Variant) -> Policy:
	_def[property] = value
	return self
