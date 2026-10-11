extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const EventNames := preload("res://avast/api/defs/event_names.gd")

const _FORWARD := {
	"enemy_killed": "enemy_killed",
	"crit_hit_landed": "crit",
	"player_damaged": "player_damaged",
	"player_healed": "player_healed",
	"player_dodged": "player_dodged",
	"experience_vial_collected": "xp_collected",
	"health_collected": "health_collected",
	"currency_spent": "currency_spent",
	"weapon_picked": "weapon_picked",
	"ability_weapon_added": "weapon_added",
	"weapon_leveled": "weapon_leveled",
	"ability_upgrade_added": "upgrade_added",
	"plugin_added": "plugin_added",
	"driver_added": "driver_added",
	"diff_picked": "protocol_picked",
	"class_picked": "class_picked",
	"safe_folder_opened": "safe_folder_opened",
}

const _END_SCREEN := "res://scenes/ui/end_screen.tscn"
const _BLUESCREEN := "res://scenes/ui/bluescreen.tscn"

static var _listeners := {}
static var _hooked := false
static var _run_won := false
static var _current := {}

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)
	_hook_game()

func on(event: String, fn: Callable) -> void:
	if not EventNames.ARGUMENTS.has(event) and not event.contains(":"):
		push_warning("[%s] events.on: unknown event '%s'. Built-in events are in Events, e.g. Events.RUN_STARTED. Custom events need a colon, e.g. '%s:%s'."
			% [_mod.mod_id, event, _mod.mod_id, event])
		return
	if not _listeners.has(event):
		_listeners[event] = []
	_listeners[event].append({"mod": _mod, "fn": fn})
	var scene: Variant = _current.get(event)
	if is_instance_valid(scene) and scene == Game.scene():
		_call.call_deferred(fn, [scene])

func off(event: String, fn: Callable) -> void:
	var list: Array = _listeners.get(event, [])
	for i in list.size():
		if list[i].mod == _mod and list[i].fn == fn:
			list.remove_at(i)
			return

func emit(event: String, args: Array = []) -> void:
	if not event.contains(":"):
		push_warning("[%s] events.emit: custom events need a colon in the name, e.g. '%s:%s'" % [_mod.mod_id, _mod.mod_id, event])
		return
	_dispatch(event, args)

static func _dispatch(event: String, args: Array) -> void:
	if event == EventNames.MAIN_MENU or event == EventNames.RUN_STARTED:
		_current[event] = args[0]
	var list: Array = _listeners.get(event, [])
	for entry in list.duplicate():
		var fn: Callable = entry.fn
		if not is_instance_valid(entry.mod) or not fn.is_valid():
			list.erase(entry)
			continue
		_call(fn, args)

static func _call(fn: Callable, args: Array) -> void:
	var count := fn.get_argument_count()
	fn.callv(args if count < 0 else args.slice(0, mini(count, args.size())))

static func _hook_game() -> void:
	if _hooked:
		return
	var tree := Game.tree()
	var ge := Game.autoload("GameEvents")
	if tree == null or ge == null:
		return
	_hooked = true
	var arg_counts := {}
	for s: Dictionary in ge.get_signal_list():
		arg_counts[s.name] = s.args.size()
	for signal_name: String in _FORWARD:
		var event: String = _FORWARD[signal_name]
		var argc: int = arg_counts.get(signal_name, 0)
		ge.connect(signal_name, func(a = null, b = null, c = null, d = null) -> void:
			_dispatch(event, [a, b, c, d].slice(0, argc)))
	ge.currency_collected.connect(func(kind: String, amount: float, _total: bool, _gain: bool) -> void:
		_dispatch("currency_collected", [kind, amount]))
	ge.battle_folder_opened.connect(func() -> void:
		var rm := Game.round_manager()
		_dispatch("round_started", [int(rm.current_battle_round) + 1 if rm != null else 1]))
	tree.node_added.connect(_on_node_added)
	if tree.current_scene != null:
		_on_node_added.call_deferred(tree.current_scene)

static func _on_node_added(node: Node) -> void:
	match node.scene_file_path:
		Game.MAIN_MENU:
			_when_ready(node, func() -> void: _dispatch("main_menu", [node]))
		Game.MAIN:
			_run_won = false
			_when_ready(node, _on_run_ready.bind(node))
			node.tree_exited.connect(func() -> void: _dispatch("run_ended", [_run_won]), Object.CONNECT_ONE_SHOT)
		_END_SCREEN:
			_run_won = true
			_dispatch("run_won", [])
		_BLUESCREEN:
			_dispatch("run_lost", [])
		_:
			if node is CharacterBody2D:
				_when_ready(node, _check_boss.bind(node))

static func _on_run_ready(main: Node) -> void:
	_dispatch("run_started", [main])
	var player := main.get_node_or_null("%Player")
	var hc: Node = player.get("health_component") if player != null else null
	if hc != null:
		hc.died.connect(func() -> void: _dispatch("player_died", []))
	var xp := main.get_node_or_null("ExperienceManager")
	if xp != null:
		xp.level_up.connect(func(level: int) -> void: _dispatch("level_up", [level]))

static func _check_boss(node: Node) -> void:
	if not node.is_in_group("boss") or node.has_meta(&"avast_boss"):
		return
	node.set_meta(&"avast_boss", true)
	_dispatch("boss_started", [node])
	var hc: Node = node.get_node_or_null("HealthComponent")
	if hc != null:
		hc.died.connect(func() -> void: _dispatch("boss_defeated", [node]), Object.CONNECT_ONE_SHOT)

static func _when_ready(node: Node, fn: Callable) -> void:
	if node.is_node_ready():
		fn.call()
	else:
		node.ready.connect(fn, Object.CONNECT_ONE_SHOT)

static func _release() -> void:
	_listeners.clear()
	_current.clear()
