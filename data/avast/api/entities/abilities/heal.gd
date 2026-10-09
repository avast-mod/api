extends "res://avast/api/entities/abilities/ability.gd"

const Heal := preload("res://avast/api/entities/abilities/heal.gd")

func trigger() -> void:
	var hc: Node = host.get_node("HealthComponent")
	if hc.already_dead:
		return
	var heal_amount := float(def.get("amount", 0.1))
	var hp: float = hc.max_health * heal_amount if heal_amount <= 1.0 else heal_amount
	hc.damage(-hp)
	host.get_tree().root.get_node("FloatingTextPool").spawn(host.global_position + Vector2.UP * 16.0, "+%d" % roundi(hp), Color.GREEN)

func amount(value: float) -> Heal:
	def.amount = value
	return self
