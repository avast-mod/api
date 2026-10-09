extends RefCounted

const Form := preload("res://avast/api/ui/form.gd")
const TipArea := preload("res://avast/api/ui/tip_area.gd")
const ShakeText := preload("res://avast/api/ui/shake_text.gd")

enum VirryAnim { CLICK, GLASSES, IDLE, IDLE_CLICK, IDLE_GLASSES, IDLE_SWORD, SHOP, SWORD, WIN }

class Item extends RefCounted:
	var control: Control
	var _build: Callable
	var _tooltip := ""
	var _disabled := false
	var _shake := Vector2.ZERO

	func _init(build: Callable) -> void:
		_build = build

	func tooltip(text: String) -> Item:
		_tooltip = text
		return self

	func shake(strength: float = 5.0, rate: float = 20.0) -> Item:
		_shake = Vector2(strength, rate)
		return self

	func disabled(on: bool = true) -> Item:
		_disabled = on
		return self

	func set_disabled(on: bool) -> void:
		_disabled = on
		if is_instance_valid(control):
			Item.apply_disabled(control, on)

	static func apply_disabled(node: Control, on: bool) -> void:
		var buttons: Array = node.find_children("*", "BaseButton", true, false)
		if node is BaseButton:
			buttons.append(node)
		if not (node is Button and not node.text.is_empty()):
			node.modulate.a = 0.5 if on else 1.0
		for button: BaseButton in buttons:
			button.disabled = on

	func build(form: Node) -> Control:
		control = _build.call(form)
		if control != null and not _tooltip.is_empty():
			if control.get("tooltip") is String:
				control.tooltip = _tooltip
			else:
				control.add_child(TipArea.new(_tooltip))
		if control != null and _disabled:
			Item.apply_disabled(control, true)
		if control != null and _shake.x > 0.0:
			ShakeText.attach(control, _shake.x, _shake.y, form.get_script())
		return control

class VirryItem extends Item:
	func tooltip(text: String) -> VirryItem:
		_tooltip = text
		return self

	func disabled(on: bool = true) -> VirryItem:
		_disabled = on
		return self

	func shake(strength: float = 5.0, rate: float = 20.0) -> VirryItem:
		_shake = Vector2(strength, rate)
		return self

	func play(animation: VirryAnim) -> void:
		if is_instance_valid(control):
			Form.play_virry(control, animation)

class Tab extends RefCounted:
	var title := ""
	var inside: Array = []
	var alert := false
	var is_disabled := false
	var on_open := Callable()
	var shaking := Vector2.ZERO

	func _init(tab_title: String, components: Array) -> void:
		title = tab_title
		inside = components

	func show_alert(on: bool = true) -> Tab:
		alert = on
		return self

	func disabled(on: bool = true) -> Tab:
		is_disabled = on
		return self

	func on_opened(fn: Callable) -> Tab:
		on_open = fn
		return self

	func shake(strength: float = 5.0, rate: float = 20.0) -> Tab:
		shaking = Vector2(strength, rate)
		return self

class TabsItem extends Item:
	func tooltip(text: String) -> TabsItem:
		_tooltip = text
		return self

	func disabled(on: bool = true) -> TabsItem:
		_disabled = on
		return self

	func shake(strength: float = 5.0, rate: float = 20.0) -> TabsItem:
		_shake = Vector2(strength, rate)
		return self

	func select(index: int) -> void:
		if is_instance_valid(control):
			control.get_meta(&"show").call(index)

	func selected() -> int:
		return control.get_meta(&"selected", 0) if is_instance_valid(control) else 0

class ProgressItem extends Item:
	func tooltip(text: String) -> ProgressItem:
		_tooltip = text
		return self

	func disabled(on: bool = true) -> ProgressItem:
		_disabled = on
		return self

	func shake(strength: float = 5.0, rate: float = 20.0) -> ProgressItem:
		_shake = Vector2(strength, rate)
		return self

	func set_value(value: float) -> void:
		if is_instance_valid(control):
			control.get_node(^"Bar").value = value

	func set_max(value: float) -> void:
		if is_instance_valid(control):
			control.get_node(^"Bar").max_value = value

	func set_color(color: Color) -> void:
		if is_instance_valid(control):
			var bar: ProgressBar = control.get_node(^"Bar")
			var fill: StyleBoxFlat = bar.get_theme_stylebox("fill").duplicate()
			fill.bg_color = color
			bar.add_theme_stylebox_override("fill", fill)

static func label(text: String) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_label(text))

static func button(text: String, on_click: Callable = Callable()) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_button(text, on_click))

static func checkbox(text: String, value: bool = false, on_change: Callable = Callable()) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_checkbox(text, value, on_change))

static func slider(text: String, value: float, min_value: float = 0.0, max_value: float = 10.0, step: float = 1.0, on_change: Callable = Callable()) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_slider(text, value, min_value, max_value, step, on_change))

static func choice(text: String, options: Array, selected: int = 0, on_change: Callable = Callable()) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_choice(text, options, selected, on_change))

static func separator() -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_separator())

static func custom(control: Control) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add(control))

static func card(title: String, description: String, icon: Variant = null, on_click: Callable = Callable(), rarity: int = -1, cost: int = -1) -> Item:
	return Item.new(func(form: Node) -> Control:
		return form.add_card(title, description, icon, on_click, rarity, cost))

static func virry(animation: VirryAnim = VirryAnim.IDLE) -> VirryItem:
	return VirryItem.new(func(form: Node) -> Control: return form.add_virry(animation))

static func progress(text: String, value: float, max_value: float = 100.0, color: Color = Color(0, 0, 0, 0)) -> ProgressItem:
	return ProgressItem.new(func(form: Node) -> Control: return form.add_progress(text, value, max_value, color))

static func keys(key_names: Array, text: String = "") -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_keys(key_names, text))

static func bubble(title: String, text: String = "", inside: Array = []) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_bubble(title, text, inside))

static func group(title: String, inside: Array) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_group(title, inside))

static func row(inside: Array) -> Item:
	return Item.new(func(form: Node) -> Control: return form.add_row(inside))

static func theme_color() -> Color:
	var theme: Resource = AppearanceManager.active_theme
	return theme.group_title_color if theme != null else Color(0, 0.275, 0.67)

static func tab(title: String, inside: Array) -> Tab:
	return Tab.new(title, inside)

static func tabs(pages: Array, selected: int = 0) -> TabsItem:
	return TabsItem.new(func(form: Node) -> Control: return form.add_tabs(pages, selected))
