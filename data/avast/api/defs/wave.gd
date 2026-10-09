extends RefCounted

const Wave := preload("res://avast/api/defs/wave.gd")

var id := ""
var _def := {}

func _init(enemy_id: String) -> void:
	id = enemy_id

func amount(value: int) -> Wave:
	_def.amount = value
	return self

func weight(value: int) -> Wave:
	_def.weight = value
	return self

func difficulty(value: int) -> Wave:
	_def.difficulty = value
	return self

func from_round(round_number: int) -> Wave:
	_def.round = round_number
	return self
