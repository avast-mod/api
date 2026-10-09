extends RefCounted

const MAIN_MENU := "main_menu"
const RUN_STARTED := "run_started"
const ROUND_STARTED := "round_started"
const SAFE_FOLDER_OPENED := "safe_folder_opened"
const RUN_WON := "run_won"
const RUN_LOST := "run_lost"
const RUN_ENDED := "run_ended"
const BOSS_STARTED := "boss_started"
const BOSS_DEFEATED := "boss_defeated"
const ENEMY_KILLED := "enemy_killed"
const CRIT := "crit"
const PLAYER_DAMAGED := "player_damaged"
const PLAYER_HEALED := "player_healed"
const PLAYER_DODGED := "player_dodged"
const PLAYER_DIED := "player_died"
const LEVEL_UP := "level_up"
const XP_COLLECTED := "xp_collected"
const HEALTH_COLLECTED := "health_collected"
const CURRENCY_COLLECTED := "currency_collected"
const CURRENCY_SPENT := "currency_spent"
const WEAPON_PICKED := "weapon_picked"
const WEAPON_ADDED := "weapon_added"
const WEAPON_LEVELED := "weapon_leveled"
const UPGRADE_ADDED := "upgrade_added"
const PLUGIN_ADDED := "plugin_added"
const DRIVER_ADDED := "driver_added"
const PROTOCOL_PICKED := "protocol_picked"
const CLASS_PICKED := "class_picked"
const LANGUAGE_CHANGED := "language_changed"

const ARGUMENTS := {
	MAIN_MENU: "menu: Node",
	RUN_STARTED: "main: Node",
	ROUND_STARTED: "round: int",
	SAFE_FOLDER_OPENED: "",
	RUN_WON: "",
	RUN_LOST: "",
	RUN_ENDED: "won: bool",
	BOSS_STARTED: "boss: Node",
	BOSS_DEFEATED: "boss: Node",
	ENEMY_KILLED: "weapon_id: String, position: Vector2, victim_name: String",
	CRIT: "position: Vector2, damage: float, is_mega: bool",
	PLAYER_DAMAGED: "amount: float",
	PLAYER_HEALED: "",
	PLAYER_DODGED: "",
	PLAYER_DIED: "",
	LEVEL_UP: "level: int",
	XP_COLLECTED: "amount: float",
	HEALTH_COLLECTED: "amount: int",
	CURRENCY_COLLECTED: "kind: String, amount: float",
	CURRENCY_SPENT: "kind: String, amount: float",
	WEAPON_PICKED: "weapon: Ability",
	WEAPON_ADDED: "weapon: Ability, current_weapons: Array",
	WEAPON_LEVELED: "weapon_id: String, level: int",
	UPGRADE_ADDED: "upgrade: AbilityUpgrade, current_upgrades: Dictionary",
	PLUGIN_ADDED: "plugin: PluginDefinition, current_plugins: Dictionary",
	DRIVER_ADDED: "driver: DriverDefinition, weapon_id: String",
	PROTOCOL_PICKED: "protocol: ProtocolSettings",
	CLASS_PICKED: "player_class: PlayerClass",
	LANGUAGE_CHANGED: "locale: String",
}

static func all() -> Array[String]:
	var out: Array[String] = []
	out.assign(ARGUMENTS.keys())
	return out
