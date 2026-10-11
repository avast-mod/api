extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Enemies := preload("res://avast/api/enemies.gd")
const Wave := preload("res://avast/api/defs/wave.gd")

const _WAVE := "res://resources/waves/wave.gd"
const _INTRO_KEYS := {
	"bat": "question", "big_basic": "bigbasic", "wizard": "critical", "big_critical": "bigcritical",
	"large_mine": "largemine", "swarm": "swarm", "mine": "mine", "burn": "burn", "shooter": "shooter",
	"dxdiag": "dxdiag", "kiter": "kiter", "crawler": "crawler", "bouncer": "bouncer",
	"big_shield": "big_shield", "leak": "leak", "click_me": "click_me",
}

static var _waves: Array[Dictionary] = []
static var _removed := {}
static var _cleared := false
static var _hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	_hook()

func add(wave: Wave) -> void:
	var enemy_id := wave.id
	var def := wave._def
	if Enemies.scene_for(enemy_id) == null:
		push_warning("[%s] waves.add: unknown enemy '%s'" % [_mod.mod_id, enemy_id])
		return
	_removed.erase(enemy_id)
	_waves.append({
		"enemy": enemy_id,
		"amount": int(def.get("amount", 1)),
		"weight": int(def.get("weight", 20)),
		"difficulty": int(def.get("difficulty", 1)),
		"round": int(def.get("round", 1)),
		"applied_to": 0,
	})
	_sync()

func remove(enemy_id: String) -> void:
	if Enemies.scene_for(enemy_id) == null:
		push_warning("[%s] waves.remove: unknown enemy '%s'" % [_mod.mod_id, enemy_id])
		return
	_removed[enemy_id] = true
	_waves.assign(_waves.filter(func(w: Dictionary) -> bool: return w.enemy != enemy_id))
	_sync()

func clear() -> void:
	_cleared = true
	_sync()

static func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	var ge := Game.autoload("GameEvents")
	ge.battle_folder_opened.connect(func() -> void: _sync.call_deferred())
	Game.tree().node_added.connect(func(node: Node) -> void:
		if node.scene_file_path == Game.MAIN:
			node.ready.connect(func() -> void: _sync.call_deferred(), Object.CONNECT_ONE_SHOT))

static func _sync() -> void:
	var em := Game.enemy_manager()
	var rm := Game.round_manager()
	if em == null or rm == null:
		return
	var table = em.enemy_wave_table
	var round_number := maxi(int(rm.current_battle_round), 1)
	if _cleared:
		for key in _INTRO_KEYS.values():
			em.introduced[key] = true
	for enemy_id in _removed:
		if _INTRO_KEYS.has(enemy_id):
			em.introduced[_INTRO_KEYS[enemy_id]] = true
	for entry in table.items.duplicate():
		var wave = entry.item
		if wave.has_meta(&"avast"):
			if _removed.has(wave.get_meta(&"avast")):
				table.remove_item(wave)
			continue
		var path: String = wave.enemy_type.resource_path
		if _cleared or _removed.keys().any(func(id: String) -> bool: return Enemies.scene_for(id).resource_path == path):
			table.remove_item(wave)
	for w in _waves:
		if w.applied_to == em.get_instance_id() or round_number < w.round:
			continue
		w.applied_to = em.get_instance_id()
		var wave: Resource = load(_WAVE).new()
		wave.enemy_type = Enemies.scene_for(w.enemy)
		wave.amount = w.amount
		wave.wave_difficulty = w.difficulty
		wave.set_meta(&"avast", w.enemy)
		table.add_item(wave, w.weight)
