extends RefCounted

const Types := preload("res://avast/api/defs/types.gd")
const PluginDef := preload("res://avast/api/defs/plugin_def.gd")

var id := ""
var _def := {}

func _init(plugin_id: String, base_id: String = "") -> void:
	id = plugin_id
	if not base_id.is_empty():
		_def.base = base_id

func base(base_id: String) -> PluginDef:
	_def.base = base_id
	return self

func behavior(script_or_path: Variant) -> PluginDef:
	_def.script = script_or_path
	return self

func name(value: String) -> PluginDef:
	_def.name = value
	return self

func description(value: String) -> PluginDef:
	_def.description = value
	return self

func icon(value: Variant) -> PluginDef:
	_def.icon = value
	return self

func rarity(value: Types.Rarity) -> PluginDef:
	_def.rarity = value
	return self

func max_stack(value: int) -> PluginDef:
	_def.max_stack = value
	return self

func field(property: String, value: Variant) -> PluginDef:
	_def[property] = value
	return self
