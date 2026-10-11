extends RefCounted

const Phase := preload("res://avast/api/defs/phase.gd")

var _def := {}

func _init(below_health: float) -> void:
	_def.below = below_health

func ability(value: RefCounted) -> Phase:
	if not _def.has("abilities"):
		_def.abilities = []
	_def.abilities.append(value)
	return self

func speed(value: float) -> Phase:
	_def.speed = value
	return self

func color(value: Color) -> Phase:
	_def.color = value
	return self

func on_enter(fn: Callable) -> Phase:
	_def.on_enter = fn
	return self
