extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func play(sound: Variant, volume_db: float = 0.0) -> void:
	var stream := Defs.sound(_mod, sound)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = &"sfx"
	player.finished.connect(player.queue_free)
	_mod.add_child(player)
	player.play()

func music(stream: Variant) -> void:
	var st := Defs.sound(_mod, stream)
	var mp := Game.autoload("MusicPlayer")
	if st == null:
		return
	mp.cancel_fade()
	mp.gameplay_stream = st
	mp.stream = st
	mp.apply_gameplay_stream()
	mp.play()

func skip() -> void:
	Game.autoload("MusicPlayer").skip_track()

func stop() -> void:
	Game.autoload("MusicPlayer").halt()
