extends "res://avast/api/mod.gd"

const Gallery := preload("res://avast/api/ui/gallery.gd")

func _ready() -> void:
	settings.on_button("developer", "components", Gallery.open.bind(self))
