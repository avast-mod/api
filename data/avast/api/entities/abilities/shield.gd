extends "res://avast/api/entities/abilities/ability.gd"

const Shield := preload("res://avast/api/entities/abilities/shield.gd")

var _left := 0.0

func trigger() -> void:
	_left = float(def.get("duration", 2.0))
	host.set_hurtbox_active(false)
	host.modulate.a = 0.5

func update(delta: float) -> void:
	super.update(delta)
	if _left > 0.0:
		_left -= delta
		if _left <= 0.0:
			_end(true)

func is_active() -> bool:
	return _left > 0.0

func reset() -> void:
	super.reset()
	_end(false)

func cancel() -> void:
	_left = 0.0
	host.modulate.a = 1.0

func _end(restore_hurtbox: bool) -> void:
	_left = 0.0
	host.modulate.a = 1.0
	if restore_hurtbox:
		host.set_hurtbox_active(true)

func duration(value: float) -> Shield:
	def.duration = value
	return self
