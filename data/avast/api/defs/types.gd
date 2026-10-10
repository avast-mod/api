extends RefCounted

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum ModifierType { FLAT, PERCENT, MULTIPLY }
enum WeaponStat { DAMAGE, SPEED, REFRESH, SIZE, AMOUNT, POWER }
enum DamageType { REPEL, HEAT, LAG, INFECT }
enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, CENTER_TOP, CENTER_BOTTOM }
enum Currency { COIN, KEYS, BEANZ }

const WEAPON_STATS: Array[String] = ["damage", "speed", "refresh", "size", "amount", "power"]
const CURRENCIES: Array[String] = ["Coin", "Keys", "Beanz"]
