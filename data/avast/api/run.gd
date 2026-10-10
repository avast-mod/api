extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")

const _END_SCREEN := "res://scenes/ui/end_screen.tscn"

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func active() -> bool:
	return Game.in_run()

func round_number() -> int:
	var rm := Game.round_manager()
	return int(rm.current_battle_round) if rm != null else 0

func time() -> float:
	var atm := Game.first_in_group("arena_time_manager")
	return float(atm.get_time_elapsed()) if atm != null else 0.0

func kills() -> int:
	var rm := Game.round_manager()
	return int(rm.total_kill_count) if rm != null else 0

func pause() -> void:
	var ge := Game.autoload("GameEvents")
	if active() and not ge.pausing:
		ge.pause_game(0.0)

func resume() -> void:
	var ge := Game.autoload("GameEvents")
	if active() and ge.pausing and not ge.processing_fullscreen:
		ge.unpause_game(0.0)

func every(seconds: float, fn: Callable) -> Timer:
	return _timer(seconds, fn, false)

func after(seconds: float, fn: Callable) -> Timer:
	return _timer(seconds, fn, true)

func _timer(seconds: float, fn: Callable, one_shot: bool) -> Timer:
	if not active():
		push_warning("[%s] run timers only work during a run" % _mod.mod_id)
		return null
	var timer := Timer.new()
	timer.wait_time = maxf(seconds, 0.01)
	timer.one_shot = one_shot
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		if fn.is_valid():
			fn.call()
		if one_shot:
			timer.queue_free())
	Game.scene().add_child(timer)
	return timer

func end(won: bool) -> void:
	if not active():
		return
	if not won:
		Game.scene().on_player_died()
		return
	Game.autoload("StatTracker").finish_run(true)
	Game.autoload("UnlockManager").evaluate_all()
	Game.autoload("MetaProgression").save()
	Game.autoload("GameEvents").spawn_overlay(load(_END_SCREEN).instantiate())
