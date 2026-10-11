extends Clickable

@export var file_id: String = ""

func double_click_action() -> void:
	super.double_click_action()
	var fn: Variant = load("res://avast/api/files.gd").get_def(file_id).get("open")
	var keep: Variant = fn.call(self) if fn is Callable and fn.is_valid() else false
	if keep is bool and keep:
		used = false
	else:
		vaporize()
