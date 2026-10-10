extends "res://avast/api/entities/abilities/ability.gd"

const Aura := preload("res://avast/api/entities/abilities/aura.gd")

var _tick_left := 0.0

func update(delta: float) -> void:
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = float(def.get("tick", 0.5))
	var target := player()
	if target != null and host.global_position.distance_to(target.global_position) <= float(def.get("radius", 48.0)):
		target.deal_contact_damage(float(def.get("damage", 5.0)), false)

func reset() -> void:
	_tick_left = 0.0

func radius(value: float) -> Aura:
	def.radius = value
	return self

func damage(value: float) -> Aura:
	def.damage = value
	return self

func tick(value: float) -> Aura:
	def.tick = value
	return self
