extends Area2D

var text := ""
var _shape := RectangleShape2D.new()
var _host: Control

func _init(tip: String) -> void:
	text = tip
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	collision.shape = _shape
	add_child(collision)
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)

func _ready() -> void:
	_host = get_parent() as Control
	_host.resized.connect(_fit)
	_host.visibility_changed.connect(_fit)
	_fit()

func _fit() -> void:
	_shape.size = _host.size
	get_child(0).position = _host.size * 0.5
	monitoring = _host.is_visible_in_tree()

func _on_entered(_area: Area2D) -> void:
	var cursor: Node = GameEvents.active_cursor
	if is_instance_valid(cursor) and not text.is_empty():
		cursor.begin_hover(self, tr(text), false)

func _on_exited(_area: Area2D) -> void:
	var cursor: Node = GameEvents.active_cursor
	if is_instance_valid(cursor):
		cursor.end_hover(self)

func _exit_tree() -> void:
	_on_exited(null)
