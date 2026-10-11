extends RefCounted

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const MAIN := "res://scenes/main/main.tscn"

static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

static func scene() -> Node:
	var t := tree()
	return t.current_scene if t != null else null

static func autoload(name: String) -> Node:
	var t := tree()
	if t == null or t.root == null:
		return null
	return t.root.get_node_or_null(name)

static func gdpatch() -> Node:
	return autoload("GDPatch")

static func first_in_group(group: String) -> Node:
	var t := tree()
	return t.get_first_node_in_group(group) if t != null else null

static func main_menu() -> Node:
	var s := scene()
	return s if s != null and s.scene_file_path == MAIN_MENU else null

static func in_run() -> bool:
	var s := scene()
	return s != null and s.scene_file_path == MAIN

static func player() -> Node:
	return first_in_group("player")

static func enemy_manager() -> Node:
	return first_in_group("enemy_manager")

static func round_manager() -> Node:
	return first_in_group("round_manager")

static func upgrade_manager() -> Node:
	return first_in_group("upgrade_manager")

static func after_ready(autoload_name: String, fn: Callable) -> void:
	var node := autoload(autoload_name)
	if node == null or node.is_node_ready():
		fn.call()
	else:
		node.ready.connect(fn, Object.CONNECT_ONE_SHOT)

static func on_scene(scene_path: String, owner_node: Node, fn: Callable) -> void:
	var t := tree()
	if t == null or not is_instance_valid(owner_node):
		return
	var current := scene()
	if current != null and current.scene_file_path == scene_path:
		_call_when_ready(current, owner_node, fn)
	var handler := func(node: Node) -> void:
		if node.scene_file_path == scene_path:
			_call_when_ready(node, owner_node, fn)
	t.node_added.connect(handler)
	owner_node.tree_exited.connect(func() -> void:
		if t.node_added.is_connected(handler):
			t.node_added.disconnect(handler)
	, Object.CONNECT_ONE_SHOT)

static func _call_when_ready(node: Node, owner_node: Node, fn: Callable) -> void:
	if not node.is_node_ready():
		await node.ready
	if is_instance_valid(owner_node) and is_instance_valid(node) and fn.is_valid():
		fn.call(node)
