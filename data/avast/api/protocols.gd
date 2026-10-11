extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Defs := preload("res://avast/api/lib/defs.gd")
const Content := preload("res://avast/api/lib/content.gd")
const Protocol := preload("res://avast/api/defs/protocol.gd")
const Starter := preload("res://avast/api/lib/starter.gd")

static var _manifest: Resource = load("res://resources/protocols/protocols_manifest.tres")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func add(definition: Protocol) -> ProtocolSettings:
	var id := definition.id
	var def := definition._def
	var base: ProtocolSettings = null
	if def.has("base"):
		base = find(str(def.base))
		if base == null:
			push_warning("[%s] protocols.add('%s'): unknown base '%s'. See protocols.list()" % [_mod.mod_id, id, def.base])
			return null
	var protocol: ProtocolSettings = Content.clone(base) if base != null else ProtocolSettings.new()
	Content.apply(_mod, protocol, def, ["id", "base", "name", "starter"], "protocols.add('%s')" % id)
	protocol.id = id
	if def.has("name"):
		protocol.protocol_name = str(def.name)
	Defs.put_by_id(_manifest.items, protocol)
	Defs.put_by_id(Game.autoload("PolicyManager").protocols, protocol)
	if def.get("starter", true):
		Starter.add_protocol(protocol)
	else:
		Starter.remove_protocol(id)
	return protocol

func select(id: String) -> bool:
	var protocol := find(id)
	if protocol == null:
		push_warning("[%s] protocols.select: unknown protocol '%s'" % [_mod.mod_id, id])
		return false
	Game.autoload("PolicyManager").select_protocol(protocol)
	Game.autoload("GameEvents").emit_diff_picked(protocol)
	return true

func current() -> String:
	var protocol: ProtocolSettings = Game.autoload("PolicyManager").base_protocol
	return protocol.id if protocol != null else ""

func find(id: String) -> ProtocolSettings:
	return Defs.find_by_id(_manifest.items, id) as ProtocolSettings

func has(id: String) -> bool:
	return find(id) != null

func list() -> Array[String]:
	var out: Array[String] = []
	for protocol in _manifest.items:
		out.append(protocol.id)
	out.sort()
	return out
