extends RefCounted

const Component := preload("res://avast/api/defs/component.gd")
const Types := preload("res://avast/api/defs/types.gd")
const _ICON := "res://assets/icons/levelup32.png"
const _CARD_ICON := "res://assets/icons/luck-icon-export.png"
const _OPTIONS := ["Mouse", "Keyboard", "Floppy", "Modem", "Printer", "Scanner"]
const _ANIMATIONS := ["Click", "Glasses", "Idle", "Idle and click", "Idle and glasses", "Idle and sword", "Shop", "Sword", "Win"]

static func open(mod: Node) -> Control:
	var status := Component.label("Click, type or pick something and it shows here.")
	var say := func(text: String) -> void:
		if is_instance_valid(status.control):
			status.control.text = text

	var name_field := Component.input("input(): a text field", "", func(text: String) -> void: say.call("input: %s" % text), "Type and press Enter")
	var notes := Component.text_area("text_area(): several lines", "Line one\nLine two", 3, func(text: String) -> void: say.call("text_area: %d characters" % text.length()))
	var amount := Component.number("number(): - and + buttons, 0 to 10", 5, 0, 10, 1, func(value: Variant) -> void: say.call("number: %s" % value))
	var tint := Component.color("color(): 48 colors and a hex code", Color("#ff8000"), func(color: Color) -> void: say.call("color: #%s" % color.to_html(false)))
	var level := Component.combo("combo(): a drop-down list", ["Easy", "Normal", "Hard", "Nightmare"], 1, func(index: int, option: String) -> void: say.call("combo: %d, %s" % [index, option]))
	var one := Component.listbox("listbox(): one pick", _OPTIONS, 0, func(index: int, option: String) -> void: say.call("listbox: %d, %s" % [index, option]), false, 4)
	var many := Component.listbox("listbox(..., true): several picks", _OPTIONS, [0, 2], func(picked: Array) -> void: say.call("listbox: %s" % [picked]), true, 4)
	var bar := Component.progress("progress(): 40 of 100", 40, 100)
	var virry := Component.virry(Component.VirryAnim.IDLE)

	var buttons := Component.tab("Buttons", [
		Component.label("label(): text. A long label wraps onto more lines when the window is too narrow for it, like this one."),
		Component.button("button()", func() -> void: say.call("button: clicked")),
		Component.row([
			Component.button(".tooltip()", func() -> void: say.call("button with a tooltip")).tooltip("A tooltip shows while the cursor rests on it."),
			Component.button(".disabled()").disabled(),
			Component.button(".shake()", func() -> void: say.call("shaking button")).shake(3),
		]),
		Component.checkbox("checkbox()", true, func(on: bool) -> void: say.call("checkbox: %s" % on)),
		Component.checkbox("checkbox().disabled()", false).disabled(),
		Component.slider("slider()", 5, 0, 10, 1, func(value: float) -> void: say.call("slider: %s" % value)),
		Component.choice("choice()", ["First", "Second", "Third"], 0, func(index: int, option: String) -> void: say.call("choice: %d, %s" % [index, option])),
		Component.separator(),
		Component.label("separator() is the line above. label().shake(8):"),
		Component.label("Shaking text").shake(8),
	])
	var lists := Component.tab("Lists", [level, one, many])
	var fields := Component.tab("Fields", [
		name_field, notes, amount, tint,
		Component.row([
			Component.button("value()", func() -> void:
				say.call("%s | %s | %s | #%s | %s" % [name_field.value(), notes.value().replace("\n", " "), amount.value(), tint.value().to_html(false), level.value()])),
			Component.button("set_value()", func() -> void:
				name_field.set_value("Ada")
				amount.set_value(7)
				tint.set_value(Color("#3ab0ff"))
				level.set_value(3)
				many.set_value([1, 3, 5])
				say.call("set_value: Ada, 7, #3ab0ff, Nightmare and three picks")),
		]),
	])
	var progress := Component.tab("Progress", [
		bar,
		Component.row([
			Component.button("- 10", func() -> void: bar.set_value(maxf(bar.value(), 0.0) - 10.0)),
			Component.button("+ 10", func() -> void: bar.set_value(maxf(bar.value(), 0.0) + 10.0)),
			Component.button("Busy", func() -> void: bar.set_value(-1)),
			Component.button("set_color()", func() -> void: bar.set_color(Color("#d03030"))),
		]),
		Component.progress("progress() below 0: busy", -1),
		Component.progress("progress() with a tint", 70, 100, Color("#40a0ff")),
		Component.separator(),
		Component.keys(["esc", "move_up", "space"], "keys():"),
		Component.row([Component.image(_ICON, Vector2(32, 32)), Component.label("image(): a picture from the game, your mod or a Texture2D.")]),
	])
	var cards := Component.tab("Cards", [
		Component.card("Lucky Charm", "card() with a rarity and a cost", _CARD_ICON, func() -> void: say.call("card: Lucky Charm"), Types.Rarity.EPIC, 25),
		Component.card("Plain card", "card() without rarity or cost", _ICON, func() -> void: say.call("card: Plain card")),
		Component.row([
			virry,
			Component.choice("virry().play()", _ANIMATIONS, 2, func(index: int, _option: String) -> void: virry.play(index)),
		]),
	])
	var layout := Component.tab("Layout", [
		Component.group("group(): a framed box, .shake(3) shakes only its title", [
			Component.label("Components inside a group."),
		]).shake(3),
		Component.row([Component.label("row(): side by side"), Component.button("Right")]),
		Component.bubble("bubble()", "The speech bubble of the starter folder.", [Component.keys(["esc"], "Close")]),
		Component.custom(_swatch()),
		Component.label("tabs() and tab(): pages, like the Personalise window."),
		Component.tabs([
			Component.tab("First", [Component.label("The first page.")]),
			Component.tab(".show_alert()", [Component.label("This tab has the orange \"!\".")]).show_alert(),
			Component.tab(".on_opened()", [Component.label("Opening it runs a function.")]).on_opened(func() -> void: say.call("tab: opened")),
			Component.tab(".shake()", [Component.label("Its title shakes.")]).shake(2),
			Component.tab(".disabled()", []).disabled(),
		]),
	])
	return mod.windows.form("Components", [
		Component.tabs([buttons, lists, fields, progress, cards, layout]),
		Component.separator(),
		status,
	], Vector2(500, 400))

static func _swatch() -> Control:
	var swatch := ColorRect.new()
	swatch.color = Component.theme_color()
	swatch.custom_minimum_size = Vector2(0, 10)
	var label := Label.new()
	label.text = "custom(): any Control, here a ColorRect in theme_color()"
	label.theme_type_variation = &"ThemeLabel"
	var box := VBoxContainer.new()
	box.add_child(label)
	box.add_child(swatch)
	return box
