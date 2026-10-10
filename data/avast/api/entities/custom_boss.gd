extends "res://avast/api/entities/custom_enemy.gd"

const Defs := preload("res://avast/api/lib/defs.gd")

var _phases: Array = []
var _phase := -1

func _definition() -> Dictionary:
	return load("res://avast/api/bosses.gd").get_def(custom_id)

func _ready() -> void:
	super()
	host.ready.connect(_apply_title, Object.CONNECT_ONE_SHOT)
	_phases = def.get("phases", []).duplicate()
	_phases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("below", 0.0) > b.get("below", 0.0))
	_health.health_changed.connect(_check_phases)

func _apply_title() -> void:
	host.boss_name_key = str(def.get("title", custom_id))
	host.boss_met_stat = ""

func _spawned() -> void:
	super()
	if def.get("music") is AudioStream:
		MusicPlayer.cancel_fade()
		MusicPlayer.stream = def.music
		MusicPlayer.play()

func _on_died() -> void:
	super()
	_call("on_defeat", [host])
	if def.get("music") is AudioStream:
		MusicPlayer.apply_gameplay_stream()
		MusicPlayer.play()

func _check_phases() -> void:
	if _health.already_dead:
		return
	var percent: float = _health.get_health_percent()
	while _phase + 1 < _phases.size() and percent <= float(_phases[_phase + 1].get("below", 0.0)):
		_phase += 1
		_enter(_phases[_phase])

func _enter(phase: Dictionary) -> void:
	if phase.has("abilities"):
		set_abilities(phase.abilities)
		for ability in abilities:
			ability.reset()
	if phase.has("speed"):
		host.max_speed = float(phase.speed) * float(GameEvents.protocol_settings["enemy_movement_speed_scale"])
	if phase.has("color"):
		var sprite := host.get_node("Visuals/Sprite2D")
		if not has_meta(&"original_look"):
			set_meta(&"original_look", sprite.texture if sprite is Sprite2D else sprite.sprite_frames)
		if sprite is Sprite2D:
			sprite.texture = get_meta(&"original_look")
		else:
			sprite.sprite_frames = get_meta(&"original_look")
		Defs.tint_sprite(sprite, phase.color)
	var fn: Variant = phase.get("on_enter")
	if fn is Callable and fn.is_valid():
		fn.call(host)
