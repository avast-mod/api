extends RefCounted

var host: CharacterBody2D
var def := {}
var every: float = 0.0
var _cooldown: float = 0.0

func _init(every_seconds: float = 0.0) -> void:
	def.every = every_seconds

func setup(p_host: CharacterBody2D, p_def: Dictionary) -> void:
	host = p_host
	def = p_def
	every = float(def.get("every", 0.0))
	_cooldown = every

func update(delta: float) -> void:
	if every <= 0.0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = every
		trigger()

func trigger() -> void:
	pass

func reset() -> void:
	_cooldown = every

func cancel() -> void:
	pass

func player() -> Node2D:
	return host.get_tree().get_first_node_in_group("player") as Node2D

func enemy_manager() -> Node:
	return host.get_tree().get_first_node_in_group("enemy_manager")

func entities_layer() -> Node:
	return host.get_tree().get_first_node_in_group("entities_layer")
