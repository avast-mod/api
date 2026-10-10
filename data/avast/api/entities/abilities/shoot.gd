extends "res://avast/api/entities/abilities/ability.gd"

const Shoot := preload("res://avast/api/entities/abilities/shoot.gd")

enum Aim { PLAYER, CIRCLE, RANDOM }

const PROJECTILE := "res://scenes/component/projectile.tscn"

func trigger() -> void:
	var shots := maxi(int(def.get("count", 1)), 1)
	var shot_speed := float(def.get("speed", 85.0)) * float(GameEvents.protocol_settings["enemy_movement_speed_scale"])
	var shot_damage := float(def.get("damage", host.get_node("HurtComponent").damage))
	for dir in _directions(shots, float(def.get("spread", 0.0))):
		var projectile: Node = host.get_tree().root.get_node("WeaponEffectPool").spawn(load(PROJECTILE), entities_layer())
		projectile.size_scale = float(def.get("size", 1.0))
		projectile.global_position = host.global_position
		projectile.setup(dir, shot_speed, shot_damage, def.get("sprite"))

func _directions(shots: int, arc: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	match int(def.get("aim", Aim.PLAYER)):
		Aim.CIRCLE:
			for i in shots:
				out.append(Vector2.from_angle(TAU * i / shots))
		Aim.RANDOM:
			for i in shots:
				out.append(Vector2.from_angle(randf() * TAU))
		_:
			var target := player()
			var toward := host.global_position.direction_to(target.global_position) if target != null else Vector2.DOWN
			for i in shots:
				var t := 0.5 if shots == 1 else float(i) / (shots - 1)
				out.append(toward.rotated(deg_to_rad(lerpf(-arc * 0.5, arc * 0.5, t))))
	return out

func count(value: int) -> Shoot:
	def.count = value
	return self

func spread(value: float) -> Shoot:
	def.spread = value
	return self

func speed(value: float) -> Shoot:
	def.speed = value
	return self

func damage(value: float) -> Shoot:
	def.damage = value
	return self

func sprite(value: Variant) -> Shoot:
	def.sprite = value
	return self

func size(value: float) -> Shoot:
	def.size = value
	return self

func aim(value: Aim) -> Shoot:
	def.aim = value
	return self
