extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")

const Types := preload("res://avast/api/defs/types.gd")
const ScreenLayer := preload("res://avast/api/ui/screen_layer.gd")
const _TOAST := "res://scenes/ui/unlock_toast/unlock_toast.tscn"
const _MAX_TOASTS := 3
const _PRESETS: Array[int] = [
	Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_LEFT,
	Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_TOP, Control.PRESET_CENTER_BOTTOM,
]

static var _huds: Array[Dictionary] = []
static var _hud_hooked := false

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod
	mod.tree_exiting.connect(_release)

func toast(title: String, detail: String = "", icon: Variant = null, seconds: float = 4.0) -> void:
	var unlocks := Game.autoload("UnlockManager")
	var overlay: Node = unlocks.toast_overlay
	var tree := Game.tree()
	while unlocks.toast_hold or overlay.slot.get_child_count() >= _MAX_TOASTS:
		await tree.create_timer(0.25).timeout
	var tex := Defs.texture(_mod, icon)
	var node: Control = load(_TOAST).instantiate()
	overlay.apply_placement(Game.main_menu() != null)
	overlay.slot.add_child(node)
	node.get_node("%Title").text = title
	node.get_node("%Detail").text = detail
	node.get_node("%Detail").visible = not detail.is_empty()
	node.get_node("%Icon").texture = tex
	node.get_node("%Icon").visible = tex != null
	node.modulate.a = 0.0
	overlay.sound.play()
	var tween := node.create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 1.0, 0.2)
	tween.tween_interval(seconds)
	tween.tween_property(node, "modulate:a", 0.0, 0.5)
	tween.tween_callback(node.queue_free)

func notify(text: String, icon: Variant = null) -> void:
	if not Game.in_run():
		toast(text, "", icon)
		return
	var bubble: Node = Game.scene().get_node_or_null("%NotifMap")
	if bubble != null:
		bubble.setup_notification(CORNER_TOP_RIGHT, Defs.texture(_mod, icon), text)

func float_text(text: String, at: Vector2, color: Color = Color.WHITE) -> void:
	if Game.in_run():
		Game.autoload("FloatingTextPool").spawn(at, text, color)

func hud(factory: Variant, corner: Types.Corner = Types.Corner.TOP_LEFT) -> void:
	var entry := {"factory": factory if factory is Callable else Defs.scene(_mod, factory), "corner": corner, "mod": _mod}
	_huds.append(entry)
	if not _hud_hooked:
		_hud_hooked = true
		Game.on_scene(Game.MAIN, Game.gdpatch() if Game.gdpatch() != null else Game.tree().root, _mount_all)
	elif Game.in_run():
		_mount(entry, Game.scene())

static func screen_rect(margin: float = 14.0) -> Rect2:
	var tree := Game.tree()
	var view := tree.root.get_visible_rect()
	var bezel: Node = tree.get_first_node_in_group(&"monitor_bezel")
	var bounds: Control = bezel.get_node_or_null("ScreenBounds") if bezel != null else null
	if bounds != null and bounds.is_inside_tree():
		var xform := bounds.get_global_transform_with_canvas()
		var screen := Rect2(xform * Vector2.ZERO, xform.basis_xform(bounds.size)).abs()
		view = view.intersection(screen) if view.intersects(screen) else view
	return view.grow(-margin)

func overlay(content: Variant, corner: Types.Corner = Types.Corner.TOP_LEFT, margin: float = 14.0) -> Control:
	var control: Control = content.call() if content is Callable else (Defs.scene(_mod, content).instantiate() if content is String else content)
	if control == null:
		push_warning("[%s] ui.overlay: needs a Control, a Callable returning one, or a scene path" % _mod.mod_id)
		return null
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mod.add_child(ScreenLayer.new(control, corner, margin, _place))
	_place(control, corner, margin)
	return control

static func _place(control: Control, corner: int, margin: float) -> void:
	var area := screen_rect(margin)
	var size := control.get_combined_minimum_size().max(control.size)
	var x := area.position.x
	var y := area.position.y
	match corner:
		Types.Corner.TOP_RIGHT, Types.Corner.BOTTOM_RIGHT:
			x = area.end.x - size.x
		Types.Corner.CENTER_TOP, Types.Corner.CENTER_BOTTOM:
			x = area.position.x + (area.size.x - size.x) / 2.0
	if corner in [Types.Corner.BOTTOM_LEFT, Types.Corner.BOTTOM_RIGHT, Types.Corner.CENTER_BOTTOM]:
		y = area.end.y - size.y
	control.position = Vector2(x, y).round()

static func _mount_all(main: Node) -> void:
	for entry in _huds:
		_mount(entry, main)

static func _mount(entry: Dictionary, main: Node) -> void:
	if not is_instance_valid(entry.mod):
		return
	var anchor: Control = main.get_tree().get_first_node_in_group(&"widget_hud_anchor")
	var widget: Control = entry.factory.call() if entry.factory is Callable else entry.factory.instantiate()
	if anchor == null or widget == null:
		return
	anchor.add_child(widget)
	widget.set_anchors_and_offsets_preset(_PRESETS[entry.corner], Control.PRESET_MODE_MINSIZE, 4)

static func _release() -> void:
	_huds.clear()
