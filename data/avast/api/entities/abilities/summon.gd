extends "res://avast/api/entities/abilities/ability.gd"

const Summon := preload("res://avast/api/entities/abilities/summon.gd")

func trigger() -> void:
	var em := enemy_manager()
	var scene: PackedScene = def.get("enemy") if def.get("enemy") is PackedScene \
		else load("res://avast/api/enemies.gd").scene_for(str(def.get("enemy", "basic")))
	if em == null or scene == null:
		return
	var spread_radius := float(def.get("radius", 48.0))
	for i in maxi(int(def.get("count", 1)), 1):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(16.0, maxf(spread_radius, 16.0))
		em.spawn_enemy_at(scene, host.global_position + offset, 1.0)

func enemy(value: Variant) -> Summon:
	def.enemy = value
	return self

func count(value: int) -> Summon:
	def.count = value
	return self

func radius(value: float) -> Summon:
	def.radius = value
	return self
