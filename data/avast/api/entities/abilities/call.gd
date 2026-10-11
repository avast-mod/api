extends "res://avast/api/entities/abilities/ability.gd"

func _init(every_seconds: float = 0.0, fn: Callable = Callable()) -> void:
	super(every_seconds)
	def.run = fn

func trigger() -> void:
	var fn: Variant = def.get("run")
	if fn is Callable and fn.is_valid():
		fn.call(host)
