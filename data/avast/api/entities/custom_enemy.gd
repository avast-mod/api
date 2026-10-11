extends Node

@export var custom_id: String = ""

var host: CharacterBody2D
var def: Dictionary
var abilities: Array = []
var _health: Node
var _sheets: Array[Sprite2D] = []
var _frame_time := 0.0

func _ready() -> void:
	host = get_parent()
	def = _definition()
	_health = host.get_node("HealthComponent")
	_health.health_decreased.connect(_on_hit)
	_health.died.connect(_on_died)
	host.visibility_changed.connect(_on_visibility_changed)
	set_abilities(def.get("abilities", []))
	if def.has("sprite") and int(def.get("frames", 1)) > 1:
		for path in ["Visuals/Sprite2D", "Shadow"]:
			var sprite := host.get_node_or_null(path) as Sprite2D
			if sprite != null:
				_sheets.append(sprite)
	set_process(not _sheets.is_empty())
	_spawned.call_deferred()

func _definition() -> Dictionary:
	return load("res://avast/api/enemies.gd").get_def(custom_id)

func set_abilities(list: Array) -> void:
	for ability in abilities:
		ability.cancel()
	abilities.clear()
	for template in list:
		var ability = template.get_script().new()
		ability.setup(host, template.def)
		abilities.append(ability)

func _process(delta: float) -> void:
	_frame_time += delta * float(def.get("fps", 8.0))
	for sprite in _sheets:
		sprite.frame = int(_frame_time) % sprite.hframes

func _physics_process(delta: float) -> void:
	if not _health.already_dead:
		for ability in abilities:
			ability.update(delta)

func _on_visibility_changed() -> void:
	if host.visible:
		_spawned.call_deferred()
	else:
		for ability in abilities:
			ability.cancel()

func _spawned() -> void:
	for ability in abilities:
		ability.reset()
	_call("on_spawn", [host])

func _on_hit(amount: float) -> void:
	_call("on_hit", [host, amount])

func _on_died() -> void:
	for ability in abilities:
		ability.cancel()
	_call("on_death", [host])

func _call(key: String, args: Array) -> void:
	var fn: Variant = def.get(key)
	if fn is Callable and fn.is_valid():
		fn.callv(args)
