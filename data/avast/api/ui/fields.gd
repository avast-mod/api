extends RefCounted

const Palette := preload("res://avast/api/ui/palette.gd")
const STD_BUTTON := preload("res://scenes/ui/standard_button/standard_button.tscn")
const _ARROW := "res://avast/api/assets/arrow_down.png"
const _MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]
const BASIC_COLORS := [
	"ff8080", "ffff80", "80ff80", "00ff80", "80ffff", "0080ff", "ff80c0", "ff80ff",
	"ff0000", "ffff00", "80ff00", "00ff40", "00ffff", "0080c0", "8080c0", "ff00ff",
	"804040", "ff8040", "00ff00", "008080", "004080", "8080ff", "800040", "ff0080",
	"800000", "ff8000", "008000", "008040", "0000ff", "0000a0", "800080", "8000ff",
	"400000", "804000", "004000", "004040", "000080", "000040", "400040", "400080",
	"000000", "808000", "808040", "808080", "408080", "c0c0c0", "400040", "ffffff",
]

static var _held := {}
static var _arrow: Texture2D

static func titled(text: String, control: Control) -> Control:
	if text.is_empty():
		return control
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"ThemeLabel"
	box.add_child(label)
	box.add_child(control)
	return box

static func field_box(pal: Dictionary) -> StyleBoxFlat:
	var style := Palette.box(pal.field, pal.border, 1, 3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	return style

static func line_edit(text: String, placeholder: String = "") -> LineEdit:
	var pal := Palette.current()
	var field := LineEdit.new()
	field.text = text
	field.placeholder_text = placeholder
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "focus", "read_only"]:
		field.add_theme_stylebox_override(state, field_box(pal))
	field.add_theme_color_override("font_color", pal.text)
	field.add_theme_color_override("font_placeholder_color", pal.muted)
	field.add_theme_color_override("caret_color", pal.text)
	field.text_submitted.connect(func(_text: String) -> void: field.release_focus())
	hold_keys_while_typing(field)
	return field

static func text_edit(text: String, rows: int) -> TextEdit:
	var pal := Palette.current()
	var area := TextEdit.new()
	area.text = text
	area.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size.y = rows * 14 + 8
	for state in ["normal", "focus", "read_only"]:
		area.add_theme_stylebox_override(state, field_box(pal))
	area.add_theme_color_override("font_color", pal.text)
	area.add_theme_color_override("caret_color", pal.text)
	hold_keys_while_typing(area)
	return area

static func hold_keys_while_typing(field: Control) -> void:
	field.focus_entered.connect(_hold_move_keys.bind(field))
	field.focus_exited.connect(_restore_move_keys.bind(field))
	field.tree_exiting.connect(_restore_move_keys.bind(field))
	field.add_child(_LetGo.new(field))

class _LetGo extends Node:
	var _field: Control

	func _init(field: Control) -> void:
		_field = field

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and _field.has_focus() and not _field.get_global_rect().has_point(_field.get_global_mouse_position()):
			_field.release_focus()

static func _hold_move_keys(field: Control) -> void:
	if not _held.is_empty():
		return
	_held[&"owner"] = field.get_instance_id()
	for action: String in _MOVE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var keys := InputMap.action_get_events(action).filter(func(event: InputEvent) -> bool: return event is InputEventKey)
		_held[action] = keys
		for event: InputEvent in keys:
			InputMap.action_erase_event(action, event)
		Input.action_release(action)

static func _restore_move_keys(field: Control) -> void:
	if _held.get(&"owner") != field.get_instance_id():
		return
	for action in _held:
		if action == &"owner":
			continue
		for event: InputEvent in _held[action]:
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	_held.clear()

static func arrow() -> Texture2D:
	if _arrow == null:
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(_ARROW)) == OK:
			_arrow = ImageTexture.create_from_image(image)
	return _arrow

static func flat_button(text: String, on_click: Callable) -> Button:
	var button: Button = STD_BUTTON.instantiate()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = true
	button.custom_minimum_size = Vector2(0, 18)
	mark_picked(button, false)
	if on_click.is_valid():
		button.clicked.connect(on_click)
	return button

static func mark_picked(button: Button, picked: bool) -> void:
	var pal := Palette.current()
	var idle: StyleBox = StyleBoxEmpty.new()
	var hover: StyleBox = Palette.box(pal.hover, Color(0, 0, 0, 0), 0, 0)
	if picked:
		idle = Palette.box(pal.select, pal.select, 0, 0)
		hover = idle
	for style in [idle, hover]:
		style.content_margin_left = 4
		style.content_margin_right = 4
	for state in ["normal", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, idle)
	for state in ["hover", "focus"]:
		button.add_theme_stylebox_override(state, hover)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, pal.select_text if picked else pal.text)

static func drop_button(on_click: Callable) -> Button:
	var pal := Palette.current()
	var button: Button = STD_BUTTON.instantiate()
	button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 20)
	var box := field_box(pal)
	box.content_margin_right = 18
	var hover := box.duplicate()
	hover.border_color = pal.accent
	for state in ["normal", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state, box)
	for state in ["hover", "focus"]:
		button.add_theme_stylebox_override(state, hover)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, pal.text)
	var mark := TextureRect.new()
	mark.texture = arrow()
	mark.modulate = pal.text
	mark.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	mark.offset_left = -12
	mark.offset_right = -5
	mark.offset_top = -2
	mark.offset_bottom = 2
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(mark)
	button.clicked.connect(on_click)
	return button

static func drop_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.box(Palette.current().field, Palette.current().border, 1, 1))
	panel.hide()
	return panel

static func combo(options: Array, selected: int, on_change: Callable) -> VBoxContainer:
	var state := {"index": clampi(selected, 0, maxi(options.size() - 1, 0))}
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	var list := drop_panel()
	var head := drop_button(func() -> void: list.visible = not list.visible)
	root.add_child(head)
	root.add_child(list)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	list.add_child(rows)
	var show := func() -> void:
		head.text = str(options[state.index]) if not options.is_empty() else ""
		for i in rows.get_child_count():
			mark_picked(rows.get_child(i), i == state.index)
	for i in options.size():
		rows.add_child(flat_button(str(options[i]), func() -> void:
			list.hide()
			if state.index == i:
				return
			state.index = i
			show.call()
			if on_change.is_valid():
				on_change.call(i, str(options[i]))))
	show.call()
	root.set_meta(&"get", func() -> int: return state.index)
	root.set_meta(&"set", func(value: Variant) -> void:
		state.index = clampi(int(value), 0, maxi(options.size() - 1, 0))
		show.call())
	return root

static func listbox(options: Array, selected: Variant, multiple: bool, rows: int, on_change: Callable) -> PanelContainer:
	var picked: Array = selected.duplicate() if selected is Array else ([] if int(selected) < 0 else [int(selected)])
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.box(Palette.current().field, Palette.current().border, 1, 1))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = rows * 18
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	scroll.add_child(column)
	var show := func() -> void:
		for i in column.get_child_count():
			var row: Button = column.get_child(i)
			mark_picked(row, picked.has(i))
			if multiple:
				row.icon = AppearanceManager.checkbox_texture(picked.has(i))
	for i in options.size():
		column.add_child(flat_button(str(options[i]), func() -> void:
			if multiple:
				if picked.has(i):
					picked.erase(i)
				else:
					picked.append(i)
				picked.sort()
			else:
				picked.assign([i])
			show.call()
			if on_change.is_valid():
				if multiple:
					on_change.call(picked.duplicate())
				else:
					on_change.call(i, str(options[i]))))
	show.call()
	watch_clipping(scroll, column)
	panel.set_meta(&"get", func() -> Variant: return picked.duplicate() if multiple else (picked[0] if not picked.is_empty() else -1))
	panel.set_meta(&"set", func(value: Variant) -> void:
		picked.assign(value if value is Array else ([] if int(value) < 0 else [int(value)]))
		show.call())
	return panel

static func clip(scroll: ScrollContainer) -> void:
	if not is_instance_valid(scroll) or not scroll.is_inside_tree():
		return
	var visible := scroll.is_visible_in_tree()
	for button in scroll.find_children("*", "StandardButton", true, false):
		var shape: CollisionShape2D = button.collision_shape_2d
		if shape != null:
			shape.disabled = not visible or not shown(button)

static func shown(control: Control) -> bool:
	var rect := control.get_global_rect()
	var node := control.get_parent()
	while node != null:
		if node is ScrollContainer and not (node as ScrollContainer).get_global_rect().intersects(rect):
			return false
		node = node.get_parent()
	return true

static func watch_clipping(scroll: ScrollContainer, content: Control) -> void:
	var later := func() -> void: clip.call_deferred(scroll)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: later.call())
	scroll.resized.connect(later)
	scroll.visibility_changed.connect(later)
	content.resized.connect(later)
	scroll.ready.connect(later)

static func number(value: float, min_value: float, max_value: float, step: float, on_change: Callable) -> HBoxContainer:
	var whole := is_equal_approx(step, roundf(step))
	var state := {"value": clampf(value, min_value, max_value)}
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var field := line_edit("")
	field.custom_minimum_size.x = 64
	field.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var show := func() -> void: field.text = str(int(state.value)) if whole else str(snappedf(state.value, step))
	var change := func(next: float) -> void:
		next = clampf(snappedf(next, step) if step > 0 else next, min_value, max_value)
		var moved: bool = not is_equal_approx(next, state.value)
		state.value = next
		show.call()
		if moved and on_change.is_valid():
			on_change.call(int(next) if whole else next)
	field.focus_exited.connect(func() -> void:
		var text := field.text.strip_edges()
		if text.is_valid_float():
			change.call(text.to_float())
		else:
			show.call())
	row.add_child(field)
	for delta in [-step, step]:
		var button: Button = STD_BUTTON.instantiate()
		button.text = "-" if delta < 0 else "+"
		button.custom_minimum_size = Vector2(22, 22)
		button.clicked.connect(func() -> void: change.call(state.value + delta))
		row.add_child(button)
	show.call()
	row.set_meta(&"get", func() -> float: return state.value)
	row.set_meta(&"set", func(next: Variant) -> void:
		state.value = clampf(float(next), min_value, max_value)
		show.call())
	return row

static func color(value: Color, on_change: Callable) -> VBoxContainer:
	var pal := Palette.current()
	var state := {"color": value}
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 1)
	var panel := drop_panel()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", Palette.box(pal.field, pal.border, 1, 4))
	var head := drop_button(func() -> void: panel.visible = not panel.visible)
	head.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.custom_minimum_size.x = 104
	var box := head.get_theme_stylebox("normal").duplicate()
	box.content_margin_left = 24
	for state_name in ["normal", "pressed", "disabled", "hover_pressed"]:
		head.add_theme_stylebox_override(state_name, box)
	var hover := box.duplicate()
	hover.border_color = pal.accent
	for state_name in ["hover", "focus"]:
		head.add_theme_stylebox_override(state_name, hover)
	var swatch := Panel.new()
	swatch.position = Vector2(4, 4)
	swatch.size = Vector2(16, 12)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(swatch)
	root.add_child(head)
	root.add_child(panel)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 4)
	panel.add_child(inside)
	var grid := GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	inside.add_child(grid)
	var hex_row := HBoxContainer.new()
	hex_row.add_theme_constant_override("separation", 4)
	var hex_label := Label.new()
	hex_label.text = "Hex"
	hex_label.add_theme_color_override("font_color", pal.text)
	hex_row.add_child(hex_label)
	var hex := line_edit("", "#rrggbb")
	hex.custom_minimum_size.x = 72
	hex.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hex_row.add_child(hex)
	inside.add_child(hex_row)
	var cells := {}
	var show := func() -> void:
		swatch.add_theme_stylebox_override("panel", Palette.box(state.color, pal.border, 1, 0))
		head.text = "#" + state.color.to_html(false)
		hex.text = head.text
		for code: String in cells:
			var picked: bool = code == state.color.to_html(false)
			cells[code].add_theme_stylebox_override("normal", Palette.box(Color(code), pal.text if picked else pal.border, 2 if picked else 1, 0))
	var pick := func(next: Color, close: bool) -> void:
		if close:
			panel.hide()
		var changed: bool = next.to_html(false) != state.color.to_html(false)
		state.color = next
		show.call()
		if changed and on_change.is_valid():
			on_change.call(next)
	for code: String in BASIC_COLORS:
		var cell: Button = STD_BUTTON.instantiate()
		cell.text = ""
		cell.custom_minimum_size = Vector2(12, 12)
		var lit := Palette.box(Color(code), pal.text, 1, 0)
		for state_name in ["pressed", "disabled", "hover_pressed"]:
			cell.add_theme_stylebox_override(state_name, Palette.box(Color(code), pal.border, 1, 0))
		for state_name in ["hover", "focus"]:
			cell.add_theme_stylebox_override(state_name, lit)
		cell.clicked.connect(func() -> void: pick.call(Color(code), true))
		grid.add_child(cell)
		cells[code] = cell
	hex.focus_exited.connect(func() -> void:
		var text := hex.text.strip_edges()
		if Color.html_is_valid(text):
			pick.call(Color.html(text), false)
		else:
			show.call())
	show.call()
	root.set_meta(&"get", func() -> Color: return state.color)
	root.set_meta(&"set", func(next: Variant) -> void:
		state.color = next if next is Color else Color.html(str(next))
		show.call())
	return root
