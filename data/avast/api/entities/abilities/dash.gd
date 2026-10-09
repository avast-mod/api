extends "res://avast/api/entities/abilities/ability.gd"

const Dash := preload("res://avast/api/entities/abilities/dash.gd")

const AIM_BEAM := "res://scenes/component/aim_beam_telegraph/aim_beam_telegraph.tscn"

var _state := ""
var _left := 0.0
var _direction := Vector2.ZERO
var _beam: Node2D = null
var _saved := {}

func trigger() -> void:
	if not _state.is_empty():
		return
	var target := player()
	_direction = host.global_position.direction_to(target.global_position) if target != null else Vector2.RIGHT
	_saved = {"uses_steering": host.uses_steering, "uses_bounce": host.uses_bounce}
	host.uses_steering = false
	host.uses_bounce = false
	var windup_time := float(def.get("windup", 0.0))
	if windup_time > 0.0 and target != null:
		_state = "windup"
		_left = windup_time
		_beam = load(AIM_BEAM).instantiate()
		_beam.start_node = host
		_beam.end_node = target
		entities_layer().add_child(_beam)
		_beam.snap_show()
	else:
		_start_dash()

func update(delta: float) -> void:
	super.update(delta)
	match _state:
		"windup":
			_left -= delta
			if is_instance_valid(_beam):
				_beam.progress = 1.0 - _left / float(def.get("windup", 1.0))
			if _left <= 0.0:
				_free_beam()
				_start_dash()
		"dash":
			_left -= delta
			host.velocity = _direction * float(def.get("speed", 250.0))
			host.move_and_slide()
			if _left <= 0.0:
				cancel()

func _start_dash() -> void:
	_state = "dash"
	_left = float(def.get("duration", 0.5))

func reset() -> void:
	super.reset()
	cancel()

func cancel() -> void:
	_free_beam()
	if not _state.is_empty():
		host.uses_steering = _saved.uses_steering
		host.uses_bounce = _saved.uses_bounce
	_state = ""

func _free_beam() -> void:
	if is_instance_valid(_beam):
		_beam.queue_free()
	_beam = null

func speed(value: float) -> Dash:
	def.speed = value
	return self

func duration(value: float) -> Dash:
	def.duration = value
	return self

func windup(value: float) -> Dash:
	def.windup = value
	return self
