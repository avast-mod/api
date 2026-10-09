extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const Policy := preload("res://avast/api/defs/policy.gd")

static var _manifest: Resource = load("res://resources/policies/policies_manifest.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: Policy) -> PolicyDefinition:
	var id := definition.id
	var def := definition._def
	var base: PolicyDefinition = null
	if def.has("base"):
		base = find(str(def.base))
		if base == null:
			push_warning("[%s] policies.add('%s'): unknown base '%s'. See policies.list()" % [_mod.mod_id, id, def.base])
			return null
	var policy: PolicyDefinition = Content.clone(base) if base != null else PolicyDefinition.new()
	Content.apply(_mod, policy, def, ["id", "base", "name", "description"], "policies.add('%s')" % id)
	policy.id = id
	if def.has("name"):
		policy.name_key = str(def.name)
	if def.has("description"):
		policy.description_key = str(def.description)
	Defs.put_by_id(_manifest.items, policy)
	var pm := Game.autoload("PolicyManager")
	Defs.put_by_id(pm.definitions, policy)
	pm.by_id[id] = policy
	pm.policies_changed.emit()
	return policy

func toggle(id: String) -> bool:
	return bool(Game.autoload("PolicyManager").toggle_policy(id))

func active(id: String) -> bool:
	var policy = Game.autoload("PolicyManager").active_definition()
	return policy != null and policy.id == id

func find(id: String) -> PolicyDefinition:
	return Defs.find_by_id(_manifest.items, id) as PolicyDefinition

func has(id: String) -> bool:
	return find(id) != null

func list() -> Array[String]:
	var out: Array[String] = []
	for policy in _manifest.items:
		out.append(policy.id)
	out.sort()
	return out
