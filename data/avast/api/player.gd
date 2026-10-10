extends RefCounted

const Game := preload("res://avast/api/lib/game.gd")
const Types := preload("res://avast/api/defs/types.gd")

var _mod: Node

func _init(mod: Node) -> void:
	_mod = mod

func node() -> Node2D:
	return Game.player() as Node2D

func position() -> Vector2:
	var p := node()
	return p.global_position if p != null else Vector2.ZERO

func health() -> float:
	var hc := _health()
	return hc.current_health if hc != null else 0.0

func max_health() -> float:
	var hc := _health()
	return hc.max_health if hc != null else 0.0

func heal(amount: float) -> void:
	var hc := _health()
	if hc != null and amount > 0.0:
		hc.damage(-amount)

func hurt(amount: float, ignore_defense: bool = false) -> void:
	var p := node()
	if p == null or amount <= 0.0:
		return
	if ignore_defense:
		p.health_component.damage(amount, "", true)
	else:
		p.deal_contact_damage(amount, false)

func level() -> int:
	var xp := Game.first_in_group("experience_manager")
	return xp.current_level if xp != null else 0

func give_xp(amount: float) -> void:
	var xp := Game.first_in_group("experience_manager")
	if xp != null and amount > 0.0:
		xp.increment_experience(amount)

func give_levels(count: int = 1) -> void:
	var xp := Game.first_in_group("experience_manager")
	if xp != null and count > 0:
		xp.grant_levels(count)

func give_coins(amount: float, currency: Types.Currency = Types.Currency.COIN, apply_gain: bool = true) -> void:
	if amount <= 0.0 or not Game.in_run():
		return
	Game.autoload("GameEvents").emit_currency_collected(Types.CURRENCIES[currency], amount, true, apply_gain)

func spend_coins(amount: float, currency: Types.Currency = Types.Currency.COIN) -> bool:
	if coins(currency) < amount:
		return false
	Game.autoload("GameEvents").emit_currency_spent(Types.CURRENCIES[currency], amount)
	return true

func coins(currency: Types.Currency = Types.Currency.COIN) -> float:
	var cm := Game.first_in_group("game_currency_manager")
	return cm.currencies.get(Types.CURRENCIES[currency], 0.0) if cm != null else 0.0

func _health() -> Node:
	var p := node()
	return p.health_component if p != null else null
