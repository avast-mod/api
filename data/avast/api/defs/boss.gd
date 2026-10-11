extends "res://avast/api/defs/enemy.gd"

const Boss := preload("res://avast/api/defs/boss.gd")
const Phase := preload("res://avast/api/defs/phase.gd")

func _init(boss_id: String, base_id: String = "beachball") -> void:
	super(boss_id, base_id)
	_def.phases = []

func title(text: String) -> Boss:
	_def.title = text
	return self

func icon(texture: Variant) -> Boss:
	_def.icon = texture
	return self

func music(stream: Variant) -> Boss:
	_def.music = stream
	return self

func phase(value: Phase) -> Boss:
	_def.phases.append(value._def)
	return self

func on_defeat(fn: Callable) -> Boss:
	_def.on_defeat = fn
	return self

func in_boss_choice(on: bool) -> Boss:
	_def.choice = on
	return self

func keep_ai(on: bool) -> Boss:
	_def.keep_ai = on
	return self

func base(base_id: String) -> Boss:
	super(base_id)
	return self

func behavior(script_or_path: Variant) -> Boss:
	super(script_or_path)
	return self

func health(value: float) -> Boss:
	super(value)
	return self

func speed(value: float) -> Boss:
	super(value)
	return self

func damage(value: float) -> Boss:
	super(value)
	return self

func knockback(value: float) -> Boss:
	super(value)
	return self

func xp(value: int) -> Boss:
	super(value)
	return self

func sprite(texture: Variant, frames: int = 1, fps: float = 8.0) -> Boss:
	super(texture, frames, fps)
	return self

func scale(value: float) -> Boss:
	super(value)
	return self

func color(value: Color) -> Boss:
	super(value)
	return self

func ability(value: RefCounted) -> Boss:
	super(value)
	return self

func on_spawn(fn: Callable) -> Boss:
	super(fn)
	return self

func on_hit(fn: Callable) -> Boss:
	super(fn)
	return self

func on_death(fn: Callable) -> Boss:
	super(fn)
	return self
