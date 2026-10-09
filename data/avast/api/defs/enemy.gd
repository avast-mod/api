extends RefCounted

const Enemy := preload("res://avast/api/defs/enemy.gd")

var id := ""
var _def := {}

func _init(enemy_id: String, base_id: String = "basic") -> void:
	id = enemy_id
	_def.base = base_id
	_def.abilities = []

func base(base_id: String) -> Enemy:
	_def.base = base_id
	return self

func behavior(script_or_path: Variant) -> Enemy:
	_def.script = script_or_path
	return self

func health(value: float) -> Enemy:
	_def.health = value
	return self

func speed(value: float) -> Enemy:
	_def.speed = value
	return self

func damage(value: float) -> Enemy:
	_def.damage = value
	return self

func knockback(value: float) -> Enemy:
	_def.knockback = value
	return self

func xp(value: int) -> Enemy:
	_def.xp = value
	return self

func sprite(texture: Variant, frames: int = 1, fps: float = 8.0) -> Enemy:
	_def.sprite = texture
	_def.frames = frames
	_def.fps = fps
	return self

func scale(value: float) -> Enemy:
	_def.scale = value
	return self

func color(value: Color) -> Enemy:
	_def.color = value
	return self

func ability(value: RefCounted) -> Enemy:
	_def.abilities.append(value)
	return self

func on_spawn(fn: Callable) -> Enemy:
	_def.on_spawn = fn
	return self

func on_hit(fn: Callable) -> Enemy:
	_def.on_hit = fn
	return self

func on_death(fn: Callable) -> Enemy:
	_def.on_death = fn
	return self
