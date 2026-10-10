extends RichTextLabel

const ShakeText := preload("res://avast/api/ui/shake_text.gd")
const _BUTTON_COLORS: Array[StringName] = [
	&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color",
	&"font_disabled_color", &"font_focus_color", &"font_outline_color",
]

var strength := 5.0
var rate := 20.0
var _source: Control
var _colors := {}
var _shown := ""

static func attach(node: Node, shake_strength: float, shake_rate: float, skip: Script = null) -> void:
	if node is Label or node is RichTextLabel or (node is Button and not node.text.is_empty()):
		var overlay: Node = node.get_node_or_null(^"AVaStShake")
		if overlay == null:
			node.add_child(ShakeText.new(node, shake_strength, shake_rate))
		else:
			overlay.strength = shake_strength
			overlay.rate = shake_rate
	for child in node.get_children():
		var script: Script = child.get_script()
		if script != ShakeText and (skip == null or script != skip):
			attach(child, shake_strength, shake_rate, skip)

func _init(source: Control, shake_strength: float, shake_rate: float) -> void:
	_source = source
	strength = shake_strength
	rate = shake_rate
	name = "AVaStShake"
	bbcode_enabled = true
	scroll_active = false
	clip_contents = false
	mouse_filter = MOUSE_FILTER_IGNORE
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	set_anchors_preset(PRESET_FULL_RECT)
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _ready() -> void:
	if _source is Button:
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		_source.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_style()
	AppearanceManager.appearance_changed.connect(_style, CONNECT_DEFERRED)

func _process(_delta: float) -> void:
	var text_now: String = _source.text if _source is RichTextLabel and _source.bbcode_enabled else _source.atr(_source.text).replace("[", "[lb]")
	var wanted := "[shake rate=%s level=%s]%s" % [rate, strength, text_now]
	if wanted != _shown:
		_shown = wanted
		text = wanted
	var align: HorizontalAlignment = _source.alignment if _source is Button else _source.horizontal_alignment
	if horizontal_alignment != align:
		horizontal_alignment = align
	if _source is Button:
		if not _source.has_theme_color_override(&"font_outline_color"):
			_source.add_theme_color_override(&"font_outline_color", Color.TRANSPARENT)
		_set_color(&"default_color", _button_color())
		_set_color(&"font_outline_color", Color.TRANSPARENT if _source.disabled else _colors[&"font_outline_color"])
	else:
		if _source.visible_characters != 0:
			_source.visible_characters = 0
		_set_color(&"default_color", _source.get_theme_color(&"default_color" if _source is RichTextLabel else &"font_color"))

func _style() -> void:
	if not is_instance_valid(_source):
		return
	var source := _source
	if source is Button:
		for color in _BUTTON_COLORS:
			source.remove_theme_color_override(color)
		for color in _BUTTON_COLORS:
			_colors[color] = source.get_theme_color(color)
			source.add_theme_color_override(color, Color.TRANSPARENT)
	var rich := source is RichTextLabel
	add_theme_font_override("normal_font", source.get_theme_font(&"normal_font" if rich else &"font"))
	add_theme_font_size_override("normal_font_size", source.get_theme_font_size(&"normal_font_size" if rich else &"font_size"))
	if rich:
		add_theme_font_override("bold_font", source.get_theme_font(&"bold_font"))
		add_theme_font_size_override("bold_font_size", source.get_theme_font_size(&"bold_font_size"))
	add_theme_constant_override("outline_size", source.get_theme_constant(&"outline_size"))
	if not source is Button:
		add_theme_color_override("font_outline_color", source.get_theme_color(&"font_outline_color"))
		add_theme_color_override("font_shadow_color", source.get_theme_color(&"font_shadow_color"))
		for constant in [&"shadow_offset_x", &"shadow_offset_y", &"shadow_outline_size"]:
			add_theme_constant_override(constant, source.get_theme_constant(constant))
		add_theme_constant_override("line_separation", source.get_theme_constant(&"line_separation" if rich else &"line_spacing"))
		autowrap_mode = source.autowrap_mode
		vertical_alignment = source.vertical_alignment
	var box := source.get_theme_stylebox(&"normal")
	if box != null:
		offset_left = box.get_margin(SIDE_LEFT)
		offset_top = box.get_margin(SIDE_TOP)
		offset_right = -box.get_margin(SIDE_RIGHT)
		offset_bottom = -box.get_margin(SIDE_BOTTOM)

func _button_color() -> Color:
	var button: Button = _source
	if button.disabled:
		return _colors[&"font_disabled_color"]
	var hovered: bool = button.get("hovered") if "hovered" in button else button.is_hovered()
	if button.button_pressed:
		return _colors[&"font_hover_pressed_color"] if hovered else _colors[&"font_pressed_color"]
	if hovered:
		return _colors[&"font_hover_color"]
	return _colors[&"font_focus_color"] if button.has_focus() else _colors[&"font_color"]

func _set_color(key: StringName, color: Color) -> void:
	if get_theme_color(key) != color:
		add_theme_color_override(key, color)
