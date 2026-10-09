extends VBoxContainer

signal closed(accepted: bool)

const STD_BUTTON := preload("res://scenes/ui/standard_button/standard_button.tscn")

func _init(text: String, icon: Texture2D, buttons: Array) -> void:
	add_theme_constant_override("separation", 10)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	if icon != null:
		var rect := TextureRect.new()
		rect.texture = icon
		rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		body.add_child(rect)
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"ThemeLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for i in buttons.size():
		var button: Button = STD_BUTTON.instantiate()
		button.text = buttons[i]
		button.custom_minimum_size = Vector2(64, 22)
		button.clicked.connect(func() -> void: closed.emit(i == 0))
		row.add_child(button)
