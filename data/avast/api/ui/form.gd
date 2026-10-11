extends VBoxContainer

const Defs := preload("res://avast/api/lib/defs.gd")
const Fields := preload("res://avast/api/ui/fields.gd")
const ProgressBarUI := preload("res://avast/api/ui/progress_bar.gd")
const ShakeText := preload("res://avast/api/ui/shake_text.gd")
const STD_BUTTON := preload("res://scenes/ui/standard_button/standard_button.tscn")
const _CARD := "res://scenes/ui/standard_button/upgrade_button.tscn"
const _VIRRY := "res://scenes/ui/virry/virry.tscn"
const _SETTING_ROW := "res://scenes/ui/setting_row/setting_row.tscn"
const _CHECKBOX := "res://scenes/ui/setting_row/setting_checkbox.tscn"
const _TAB_BUTTON := "res://scenes/ui/window_tab_button.tscn"
const _ALERT := "res://scenes/ui/new_alert.tscn"
const _GROUP := "res://scenes/ui/group_box.tscn"
const _PROMPT_ICON := "res://scenes/ui/prompt_icon.gd"
const _ICON_TEXTURE := "res://addons/controller_icons/objects/ControllerIconTexture.gd"
const _TITLE_FONT := "res://inter-600.tres"
const _VIRRY_ANIMATIONS: Array[StringName] = [&"Click", &"Glasses", &"Idle", &"Idle&Click", &"Idle&Glasses", &"Idle&Sword", &"Shop", &"Sword", &"Win"]

var mod: Node

func _init() -> void:
	add_theme_constant_override("separation", 4)

func add_label(text: String) -> Label:
	var label := _label(text)
	add_child(label)
	return label

func add_button(text: String, on_click: Callable = Callable()) -> Button:
	var button := _button(text)
	if on_click.is_valid():
		button.clicked.connect(on_click)
	add_child(button)
	return button

func add_checkbox(label: String, value: bool, on_change: Callable = Callable()) -> HBoxContainer:
	var row: HBoxContainer = load(_SETTING_ROW).instantiate()
	var box: Button = load(_CHECKBOX).instantiate()
	var state := {"on": value}
	var refresh := func() -> void:
		box.set_pressed_no_signal(state.on)
		box.get_node("Check").texture = AppearanceManager.large_checkbox_texture(state.on)
	row.get_node("%Controls").add_child(box)
	row.ready.connect(func() -> void:
		row.set_label(label)
		refresh.call(), CONNECT_ONE_SHOT)
	box.clicked.connect(func() -> void:
		if box.disabled:
			return
		state.on = not state.on
		refresh.call()
		if on_change.is_valid():
			on_change.call(state.on))
	add_child(row)
	return row

func add_slider(label: String, value: float, min_value: float, max_value: float, step: float = 1.0, on_change: Callable = Callable()) -> HBoxContainer:
	var state := {"value": clampf(value, min_value, max_value)}
	var row := HBoxContainer.new()
	var text := Label.new()
	text.theme_type_variation = &"ThemeLabel"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var refresh := func() -> void:
		var shown: Variant = int(state.value) if is_equal_approx(step, roundf(step)) else snappedf(state.value, step)
		text.text = "%s: %s" % [label, shown]
	refresh.call()
	row.add_child(text)
	for delta in [-step, step]:
		var button := _button("-" if delta < 0 else "+")
		button.custom_minimum_size.x = 22
		button.clicked.connect(func() -> void:
			state.value = clampf(state.value + delta, min_value, max_value)
			refresh.call()
			if on_change.is_valid():
				on_change.call(state.value))
		row.add_child(button)
	add_child(row)
	return row

func add_choice(label: String, options: Array, selected: int = 0, on_change: Callable = Callable()) -> Button:
	var state := {"index": clampi(selected, 0, maxi(options.size() - 1, 0))}
	var button := _button("")
	var refresh := func() -> void: button.text = "%s: %s" % [label, options[state.index] if not options.is_empty() else ""]
	refresh.call()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clicked.connect(func() -> void:
		if options.is_empty():
			return
		state.index = (state.index + 1) % options.size()
		refresh.call()
		if on_change.is_valid():
			on_change.call(state.index, str(options[state.index])))
	add_child(button)
	return button

func add_input(label: String, value: String, placeholder: String, on_change: Callable) -> Control:
	var field := Fields.line_edit(value, placeholder)
	var last := {"text": value}
	field.focus_exited.connect(func() -> void:
		if field.text != last.text:
			last.text = field.text
			if on_change.is_valid():
				on_change.call(field.text))
	var control := Fields.titled(label, field)
	control.set_meta(&"get", func() -> String: return field.text)
	control.set_meta(&"set", func(text: Variant) -> void:
		field.text = str(text)
		last.text = field.text)
	add_child(control)
	return control

func add_text_area(label: String, value: String, rows: int, on_change: Callable) -> Control:
	var area := Fields.text_edit(value, rows)
	var last := {"text": value}
	area.focus_exited.connect(func() -> void:
		if area.text != last.text:
			last.text = area.text
			if on_change.is_valid():
				on_change.call(area.text))
	var control := Fields.titled(label, area)
	control.set_meta(&"get", func() -> String: return area.text)
	control.set_meta(&"set", func(text: Variant) -> void:
		area.text = str(text)
		last.text = area.text)
	add_child(control)
	return control

func add_number(label: String, value: float, min_value: float, max_value: float, step: float, on_change: Callable) -> Control:
	return _add_field(label, Fields.number(value, min_value, max_value, step, on_change))

func add_combo(label: String, options: Array, selected: int, on_change: Callable) -> Control:
	return _add_field(label, Fields.combo(options, selected, on_change))

func add_listbox(label: String, options: Array, selected: Variant, multiple: bool, rows: int, on_change: Callable) -> Control:
	return _add_field(label, Fields.listbox(options, selected, multiple, rows, on_change))

func add_color(label: String, value: Color, on_change: Callable) -> Control:
	return _add_field(label, Fields.color(value, on_change))

func add_image(texture: Variant, size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = Defs.texture(mod, texture)
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if size != Vector2.ZERO:
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.custom_minimum_size = size
	add_child(image)
	return image

func _add_field(label: String, field: Control) -> Control:
	var control := Fields.titled(label, field)
	if control != field:
		control.set_meta(&"get", field.get_meta(&"get"))
		control.set_meta(&"set", field.get_meta(&"set"))
	add_child(control)
	return control

func add_separator() -> Control:
	var line := Panel.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.theme_type_variation = &"DivHorizontal"
	add_child(line)
	return line

func add_card(title: String, description: String, icon: Variant, on_click: Callable, rarity: int, cost: int) -> Button:
	var card: Button = load(_CARD).instantiate()
	card.ready.connect(_setup_card.bind(card, title, description, Defs.texture(mod, icon), rarity, cost), CONNECT_ONE_SHOT)
	card.clicked.connect(func() -> void:
		if on_click.is_valid():
			on_click.call()
		card.set_deferred("disabled", false))
	add_child(card)
	return card

func _setup_card(card: Button, title: String, description: String, icon: Texture2D, rarity: int, cost: int) -> void:
	for node in card.find_children("*", "CanvasItem", true, false):
		node.z_index = 0
	card.driver_pips.hide()
	_stretch_title_row(card)
	card.title.text = title
	card.description.text = description
	card.apply_theme_label_to_rich_text(card.description)
	card.set_icon_vis(1)
	card.single_icon.texture = icon
	if rarity >= 0:
		var info := AbilityUpgrade.new()
		card.apply_rarity_badge(info.get_rarity_string(rarity), Color.html(info.rarity_colors[rarity]), info.rarity_text_fx[rarity])
		card.rarity_bg.modulate = info.rarity_colorhtml[rarity]
	else:
		card.rarity.hide()
		card.rarity_bg.modulate = Color.WHITE
	card.cost.visible = cost >= 0
	if cost >= 0:
		card.cost_label.text = str(cost)

static func _stretch_title_row(card: Button) -> void:
	var row: HBoxContainer = card.title.get_parent()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", row.get_theme_constant("separation"))
	for child in row.get_children():
		child.reparent(top, false)
	row.add_sibling(top)
	row.get_parent().remove_child(row)
	row.queue_free()
	card.title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func add_virry(animation: int) -> Control:
	var virry: Control = load(_VIRRY).instantiate()
	virry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	virry.size_flags_vertical = Control.SIZE_SHRINK_END
	var sprite: AnimatedSprite2D = virry.get_node("Anim")
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if frame != null:
		virry.custom_minimum_size = frame.get_size()
		sprite.position = frame.get_size() * 0.5
	add_child(virry)
	play_virry(virry, animation)
	return virry

static func play_virry(virry: Control, animation: int) -> void:
	virry.get_node("Anim").play(_VIRRY_ANIMATIONS[clampi(animation, 0, _VIRRY_ANIMATIONS.size() - 1)])

func add_progress(text: String, value: float, max_value: float, tint: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if not text.is_empty():
		box.add_child(_label(text))
	var bar: Control = ProgressBarUI.new(0, 16)
	bar.name = "Bar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.tint = tint if tint.a > 0.0 else Color.WHITE
	box.add_child(bar)
	box.set_meta(&"value", value)
	box.set_meta(&"max", max_value)
	show_progress(box)
	add_child(box)
	return box

static func show_progress(box: Control) -> void:
	var value: float = box.get_meta(&"value")
	var max_value: float = box.get_meta(&"max")
	box.get_node(^"Bar").value = -1.0 if value < 0.0 or max_value <= 0.0 else clampf(value / max_value, 0.0, 1.0)

func add_keys(keys: Array, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	if not text.is_empty():
		var label := Label.new()
		label.text = text
		label.theme_type_variation = &"FuzzyType"
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
	for key in keys:
		var name := str(key)
		var tex: Texture2D = load(_ICON_TEXTURE).new()
		tex.path = name if name.contains("/") or InputMap.has_action(name) else "key/" + name.to_lower()
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(16, 16)
		icon.texture = tex
		icon.set_script(load(_PROMPT_ICON))
		row.add_child(icon)
	add_child(row)
	return row

func add_bubble(title: String, text: String, inside: Array) -> PanelContainer:
	var bubble := PanelContainer.new()
	bubble.theme_type_variation = &"SpeechBubble"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	bubble.add_child(column)
	if not title.is_empty():
		var heading := Label.new()
		heading.theme_type_variation = &"FuzzyType"
		heading.add_theme_font_override("font", load(_TITLE_FONT))
		heading.text = title
		column.add_child(heading)
	if not text.is_empty():
		var body := Label.new()
		body.theme_type_variation = &"FuzzyType"
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.text = text
		column.add_child(body)
	if not inside.is_empty():
		var nested: VBoxContainer = get_script().new()
		nested.mod = mod
		nested.add_theme_constant_override("separation", 1)
		column.add_child(nested)
		for item in inside:
			nested.add_item(item)
	add_child(bubble)
	return bubble

func add_group(title: String, inside: Array) -> Control:
	var group: Control = load(_GROUP).instantiate()
	group.title = title
	var nested: VBoxContainer = get_script().new()
	nested.mod = mod
	group.add_child(nested)
	for item in inside:
		nested.add_item(item)
	add_child(group)
	return group

func add_tabs(tabs: Array, selected: int) -> VBoxContainer:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	var bar := HBoxContainer.new()
	bar.z_index = 1
	bar.add_theme_constant_override("separation", 1)
	var gap := Control.new()
	gap.custom_minimum_size.x = 1
	bar.add_child(gap)
	root.add_child(bar)
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0)
	shadow.shadow_color = Color(0, 0, 0, 0.1254902)
	shadow.shadow_size = 2
	shadow.shadow_offset = Vector2(1, 1)
	frame.add_theme_stylebox_override("panel", shadow)
	root.add_child(frame)
	var buttons: Array[Button] = []
	var pages: Array[Control] = []
	for tab in tabs:
		var button: Button = load(_TAB_BUTTON).instantiate()
		button.text = tab.title
		button.custom_minimum_size = Vector2(maxf(72, button.get_theme_font("font").get_string_size(tab.title).x + 20), 18)
		if tab.alert:
			var alert: Control = load(_ALERT).instantiate()
			alert.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			alert.offset_left = -16
			alert.offset_top = -6
			alert.offset_right = -4
			alert.offset_bottom = 6
			button.add_child(alert)
		button.disabled = tab.is_disabled
		if tab.shaking.x > 0.0:
			ShakeText.attach(button, tab.shaking.x, tab.shaking.y)
		bar.add_child(button)
		buttons.append(button)
		var page := PanelContainer.new()
		page.theme_type_variation = &"GradientPanel"
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		page.add_child(scroll)
		var content: VBoxContainer = get_script().new()
		content.mod = mod
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(content)
		Fields.watch_clipping(scroll, content)
		for item in tab.inside:
			content.add_item(item)
		frame.add_child(page)
		pages.append(page)
	var show := func(index: int) -> void:
		root.set_meta(&"selected", index)
		for i in pages.size():
			pages[i].visible = i == index
			buttons[i].set_pressed_no_signal(i == index)
			buttons[i].z_index = 1 if i == index else 0
	for i in buttons.size():
		buttons[i].clicked.connect(func() -> void:
			show.call(i)
			if tabs[i].on_open.is_valid():
				tabs[i].on_open.call())
	root.set_meta(&"show", show)
	show.call(clampi(selected, 0, maxi(pages.size() - 1, 0)))
	root.tree_entered.connect(func() -> void:
		var nested := _inside_scroll()
		root.size_flags_vertical = Control.SIZE_FILL if nested else Control.SIZE_EXPAND_FILL
		for page in pages:
			page.get_child(0).vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if nested else ScrollContainer.SCROLL_MODE_AUTO, CONNECT_ONE_SHOT)
	add_child(root)
	return root

func _inside_scroll() -> bool:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false

func add_row(inside: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var cells: Array[Control] = []
	for item in inside:
		var cell: VBoxContainer = get_script().new()
		cell.mod = mod
		row.add_child(cell)
		cell.add_item(item)
		cells.append(cell)
	var growing := cells.filter(_grows)
	for cell in cells:
		if not growing.is_empty():
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if cell in growing else Control.SIZE_SHRINK_CENTER
		else:
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if cell != cells.back() or cells.size() == 1 else Control.SIZE_SHRINK_END
	add_child(row)
	return row

static func _grows(cell: Control) -> bool:
	for child in cell.get_children():
		if child is Label and child.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return true
		if child is RichTextLabel or child is Container or (child is Control and child.size_flags_horizontal & Control.SIZE_EXPAND):
			return true
	return false

func add_item(item: Variant) -> void:
	if item is Control:
		add(item)
	elif item != null and item.has_method("build"):
		item.build(self)

func add(control: Control) -> Control:
	add_child(control)
	return control

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"ThemeLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text: String) -> Button:
	var button: Button = STD_BUTTON.instantiate()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.custom_minimum_size.y = 22
	return button
