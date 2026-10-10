extends CanvasLayer

var content: Control
var corner := 0
var margin := 14.0
var _place: Callable

func _init(control: Control, at: int, inset: float, place: Callable) -> void:
	content = control
	corner = at
	margin = inset
	_place = place
	layer = 126
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(control)
	control.tree_exited.connect(queue_free)

func _process(_delta: float) -> void:
	if is_instance_valid(content):
		_place.call(content, corner, margin)
