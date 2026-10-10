extends Control

const _FILL := "res://scenes/ui/progress_fill.tres"
const _WELL := "res://assets/ui/ui-progressbg.png"
const _EDGE := 3
const _BLOCKS := 4
const _SPEED := 50.0

var value := -1.0:
	set(fraction):
		value = fraction
		queue_redraw()

var tint := Color.WHITE:
	set(color):
		tint = color
		queue_redraw()

var _well := StyleBoxTexture.new()

func _init(width: float = 70.0, height: float = 14.0) -> void:
	custom_minimum_size = Vector2(width, height)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_well.texture_margin_left = _EDGE + 1
	_well.texture_margin_top = _EDGE + 1
	_well.texture_margin_right = _EDGE
	_well.texture_margin_bottom = _EDGE

func _process(_delta: float) -> void:
	if value < 0.0 and is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	var theme: Resource = AppearanceManager.active_theme
	_well.texture = theme.progress_well if theme != null and theme.get("progress_well") != null else load(_WELL)
	draw_style_box(_well, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(_EDGE, _EDGE), size - Vector2(_EDGE, _EDGE) * 2)
	if inner.size.x <= 0.0:
		return
	var fill: StyleBox = load(_FILL)
	if tint != Color.WHITE and fill is StyleBoxTexture:
		fill = fill.duplicate()
		fill.modulate_color = tint
	var tile := 8.0
	if fill is StyleBoxTexture and fill.texture != null:
		tile = fill.texture.get_width()
	if value >= 0.0:
		var width := inner.size.x if value >= 1.0 else floorf(value * inner.size.x / tile) * tile
		if width > 0.0:
			draw_style_box(fill, Rect2(inner.position, Vector2(width, inner.size.y)))
		return
	var start := floorf(fmod(Time.get_ticks_msec() / 1000.0 * _SPEED, inner.size.x))
	for i in _BLOCKS:
		var left := fmod(start + i * tile, inner.size.x)
		var right := minf(left + tile, inner.size.x)
		draw_style_box(fill, Rect2(inner.position.x + left, inner.position.y, right - left, inner.size.y))
		if left + tile > inner.size.x:
			draw_style_box(fill, Rect2(inner.position.x, inner.position.y, left + tile - inner.size.x, inner.size.y))
