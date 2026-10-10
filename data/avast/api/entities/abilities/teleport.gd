extends "res://avast/api/entities/abilities/ability.gd"

const Teleport := preload("res://avast/api/entities/abilities/teleport.gd")

func trigger() -> void:
	var target := player()
	var em := enemy_manager()
	if target == null or em == null:
		return
	var jump := float(def.get("distance", 100.0))
	host.global_position = em.find_valid_clickable_near(target.global_position, jump * 0.75, jump)
	host.reset_physics_interpolation()
	host.activate_body_collision_delayed()

func distance(value: float) -> Teleport:
	def.distance = value
	return self
