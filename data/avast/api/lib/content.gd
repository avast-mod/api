extends RefCounted

const Defs := preload("res://avast/api/lib/defs.gd")

const ENUM_ALIASES := {"percent": "additive", "add": "additive", "multiply": "multiplicative"}

static func apply(mod: Node, res: Resource, def: Dictionary, skip: Array, what: String) -> void:
	var props := {}
	for p: Dictionary in res.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props[p.name] = p
	for key in def:
		if key in skip:
			continue
		if not props.has(key):
			push_warning("[%s] %s: '%s' is not a field of %s. Fields: %s" % [mod.mod_id, what, key, res.get_script().get_global_name(), ", ".join(props.keys())])
			continue
		var p: Dictionary = props[key]
		var v: Variant = def[key]
		if key == "rarity_values":
			var values: Dictionary = res.rarity_values.duplicate()
			Defs.rarity_values(values, v)
			res.rarity_values = values
		elif p.hint == PROPERTY_HINT_ENUM and p.type == TYPE_INT and typeof(v) != TYPE_INT:
			res.set(key, enum_index(p.hint_string, v, mod, key))
		elif p.class_name == &"Texture2D":
			res.set(key, Defs.texture(mod, v))
		elif p.class_name == &"PackedScene":
			res.set(key, Defs.scene(mod, v))
		elif p.type == TYPE_DICTIONARY or p.type == TYPE_ARRAY:
			var typed: Variant = res.get(key).duplicate()
			typed.assign(v)
			res.set(key, typed)
		else:
			res.set(key, type_convert(v, p.type))

static func enum_index(hint_string: String, v: Variant, mod: Node, key: String) -> int:
	var wanted := str(v).to_lower()
	wanted = ENUM_ALIASES.get(wanted, wanted)
	var names := hint_string.split(",")
	for i in names.size():
		var entry := names[i].split(":")
		if entry[0].strip_edges().to_lower() == wanted:
			return int(entry[1]) if entry.size() > 1 else i
	push_warning("[%s] '%s' is not a valid %s. Valid: %s" % [mod.mod_id, v, key, hint_string.to_lower()])
	return 0

static func clone(res: Resource) -> Resource:
	return res.duplicate(true)
