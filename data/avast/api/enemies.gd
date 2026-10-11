extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

const Enemy := preload("res://avast/api/defs/enemy.gd")
const GLUE := preload("res://avast/api/entities/custom_enemy.gd")

const VANILLA := {
	"basic": "res://scenes/game_object/enemies/basic_enemy/basic_enemy.tscn",
	"big_basic": "res://scenes/game_object/enemies/basic_enemy/basic_enemy_two.tscn",
	"crawler": "res://scenes/game_object/enemies/basic_enemy/crawler_enemy.tscn",
	"big_shield": "res://scenes/game_object/enemies/basic_enemy/big_shield_enemy.tscn",
	"bat": "res://scenes/game_object/enemies/bat_enemy/bat_enemy.tscn",
	"wizard": "res://scenes/game_object/enemies/wizard_enemy/wizard_enemy.tscn",
	"big_critical": "res://scenes/game_object/enemies/wizard_enemy/big_critical_enemy.tscn",
	"mine": "res://scenes/game_object/enemies/mine_enemy/mine_enemy.tscn",
	"large_mine": "res://scenes/game_object/enemies/mine_enemy/large_mine_enemy.tscn",
	"swarm": "res://scenes/game_object/enemies/swarm_enemy/swarm_enemy.tscn",
	"shooter": "res://scenes/game_object/enemies/stationary_shooter_enemy/stationary_shooter_enemy.tscn",
	"kiter": "res://scenes/game_object/enemies/kiter_enemy/kiter_enemy.tscn",
	"bouncer": "res://scenes/game_object/enemies/bouncer_enemy/bouncer_enemy.tscn",
	"burn": "res://scenes/game_object/enemies/burning_disc_enemy/burning_disc_enemy.tscn",
	"dxdiag": "res://scenes/game_object/enemies/dxdiag_enemy/dxdiag_enemy.tscn",
	"leak": "res://scenes/game_object/enemies/memory_leak_enemy/memory_leak_enemy.tscn",
	"click_me": "res://scenes/game_object/enemies/click_me_enemy/click_me_enemy.tscn",
	"blocker": "res://scenes/game_object/enemies/blocker_enemy/blocker_enemy.tscn",
	"elite_error": "res://scenes/game_object/enemies/elites/elite_error/elite_error.tscn",
	"elite_question": "res://scenes/game_object/enemies/elites/elite_question/elite_question.tscn",
	"elite_crawler": "res://scenes/game_object/enemies/elites/elite_crawler/elite_crawler.tscn",
	"elite_avn_buddy": "res://scenes/game_object/enemies/elites/elite_avn_buddy/elite_avn_buddy.tscn",
}

static var _scenes := {}
static var _defs := {}

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)

func add(enemy: Enemy) -> PackedScene:
	var id := enemy.id
	var def := enemy._def
	var base := scene(str(def.get("base", "basic")))
	if base == null:
		push_warning("[%s] enemies.add('%s'): unknown base '%s'. See enemies.list()" % [_mod.mod_id, id, def.get("base")])
		return null
	var prepared := prepare(_mod, def)
	_defs[id] = prepared
	var packed := Defs.repack(base, _mod.path("enemies/%s.tscn" % id), func(root: Node) -> void:
		build(_mod, root, prepared)
		var glue: Node = root.get_node_or_null("AVaStGlue")
		if glue == null:
			glue = GLUE.new()
			glue.name = "AVaStGlue"
			root.add_child(glue)
			glue.owner = root
		glue.custom_id = id)
	if packed == null:
		_defs.erase(id)
		return null
	_scenes[id] = packed
	return packed

func spawn(id: String, at: Variant = null, health_multiplier: float = -1.0) -> Node2D:
	var sc := scene(id)
	var em := Game.enemy_manager()
	if sc == null or em == null:
		if sc == null:
			push_warning("[%s] enemies.spawn: unknown enemy '%s'" % [_mod.mod_id, id])
		return null
	if health_multiplier < 0.0:
		health_multiplier = 1.0 + (Game.round_manager().current_battle_round - 1.0) / 2.0
	var enemy: Node2D = Game.autoload("EnemyPool").spawn(sc, em.entities_layer)
	enemy.global_position = at if at is Vector2 else em.resolve_spawn_position(enemy)
	enemy.configure_spawn(health_multiplier)
	enemy.prepare_for_spawn()
	enemy.reset_physics_interpolation()
	em.all_agents.append(enemy)
	return enemy

func alive() -> Array[Node2D]:
	var out: Array[Node2D] = []
	var em := Game.enemy_manager()
	if em != null:
		for enemy in em.all_agents:
			if is_instance_valid(enemy) and enemy.visible and not enemy.health_component.already_dead:
				out.append(enemy)
	return out

func scene(id: String) -> PackedScene:
	return scene_for(id)

func has(id: String) -> bool:
	return _scenes.has(id) or VANILLA.has(id)

func list() -> Array[String]:
	var out: Array[String] = []
	out.assign(VANILLA.keys() + _scenes.keys())
	out.sort()
	return out

static func scene_for(id: String) -> PackedScene:
	if _scenes.has(id):
		return _scenes[id]
	return load(VANILLA[id]) if VANILLA.has(id) else null

static func get_def(id: String) -> Dictionary:
	return _defs.get(id, {})

static func prepare(mod: Node, def: Dictionary) -> Dictionary:
	var out := def.duplicate()
	out.abilities = _prepare_abilities(mod, out.get("abilities", []))
	var phases := []
	for entry in out.get("phases", []):
		var phase: Dictionary = entry.duplicate()
		if phase.has("abilities"):
			phase.abilities = _prepare_abilities(mod, phase.abilities)
		phases.append(phase)
	out.phases = phases
	if out.has("music"):
		out.music = Defs.sound(mod, out.music)
	return out

static func _prepare_abilities(mod: Node, list: Array) -> Array:
	var out := []
	for ability in list:
		if not (ability is RefCounted and ability.get("def") is Dictionary):
			push_warning("[%s] enemy abilities must be ability objects, e.g. Abilities.Shoot.new(2.0), got %s" % [mod.mod_id, ability])
			continue
		if ability.def.has("sprite"):
			ability.def.sprite = Defs.texture(mod, ability.def.sprite)
		if ability.def.get("enemy") is String and ability.def.enemy.contains("/"):
			ability.def.enemy = Defs.scene(mod, ability.def.enemy)
		out.append(ability)
	return out

static func build(mod: Node, root: Node, def: Dictionary) -> void:
	if def.has("script"):
		Defs.swap_script(root, Defs.script(mod, def.script))
	if def.has("speed"):
		root.max_speed = float(def.speed)
	if def.has("health"):
		root.get_node("HealthComponent").max_health = float(def.health)
	var hurt := root.get_node_or_null("HurtComponent")
	if hurt != null:
		if def.has("damage"):
			hurt.damage = float(def.damage)
		if def.has("knockback"):
			hurt.knockback_strength = float(def.knockback)
	var drop := root.get_node_or_null("ExpDropComponent")
	if drop != null and def.has("xp"):
		drop.amount = int(def.xp)
		if int(def.xp) <= 0:
			drop.drop_percent = 0.0
	var visuals: Node2D = root.get_node_or_null("Visuals")
	var shadow: Node2D = root.get_node_or_null("Shadow")
	if def.has("sprite"):
		var tex := Defs.texture(mod, def.sprite)
		if tex != null:
			var frames := maxi(int(def.get("frames", 1)), 1)
			for sprite in [root.get_node_or_null("Visuals/Sprite2D"), shadow]:
				_set_texture(sprite, tex, frames, float(def.get("fps", 8.0)))
	if def.has("scale"):
		for node in [visuals, shadow]:
			if node != null:
				node.scale = Vector2.ONE * float(def.scale)
	if def.has("color"):
		Defs.tint_sprite(root.get_node_or_null("Visuals/Sprite2D"), def.color)

static func _set_texture(sprite: Node, tex: Texture2D, frames: int, fps: float) -> void:
	if sprite is Sprite2D:
		sprite.texture = tex
		sprite.hframes = frames
		sprite.frame = 0
	elif sprite is AnimatedSprite2D:
		var sf := SpriteFrames.new()
		var width := tex.get_width() / frames
		for i in frames:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * width, 0, width, tex.get_height())
			sf.add_frame(&"default", atlas)
		sf.set_animation_speed(&"default", fps)
		sf.rename_animation(&"default", &"idle")
		sprite.sprite_frames = sf
		sprite.animation = &"idle"
		sprite.play(&"idle")

static func _release() -> void:
	_defs.clear()
