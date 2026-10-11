extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func on_scene(scene_path: String, fn: Callable) -> void:
	Game.on_scene(scene_path, _mod, fn)

func on_node(group_or_class: String, fn: Callable) -> void:
	var tree := Game.tree()
	var check := func(n: Node) -> void:
		if is_instance_valid(n) and fn.is_valid() and _matches(n, group_or_class):
			fn.call(n)
	var handler := func(n: Node) -> void:
		if n.is_node_ready():
			check.call(n)
		else:
			n.ready.connect(check.bind(n), Object.CONNECT_ONE_SHOT)
	tree.node_added.connect(handler)
	_mod.tree_exited.connect(func() -> void: tree.node_added.disconnect(handler), Object.CONNECT_ONE_SHOT)

func node(path_in_scene: String) -> Node:
	var s := Game.scene()
	return s.get_node_or_null(path_in_scene) if s != null else null

func replace_scene(original_path: String, new_scene: Variant) -> bool:
	var sc := Defs.scene(_mod, new_scene)
	if sc == null:
		return false
	sc.take_over_path(original_path)
	return true

static func _matches(n: Node, group_or_class: String) -> bool:
	if n.is_in_group(group_or_class) or n.is_class(group_or_class):
		return true
	var script: Script = n.get_script()
	while script != null:
		if script.get_global_name() == group_or_class:
			return true
		script = script.get_base_script()
	return false
