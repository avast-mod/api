# <img src="icon.png" width="32" height="32" alt=""> AVaSt API

A GDScript modding API for AVS2003PRO, running on the [GDPatch](https://gdpatch.dev) mod loader.

```gdscript
extends "res://avast/api/mod.gd"

func _ready() -> void:
    enemies.add(
        Enemy.new("cinder_hornet", "bat")
            .health(18)
            .color(Color("#ff7a1a"))
            .ability(Abilities.Shoot.new(2.5).count(3).spread(40))
    )
    waves.add(Wave.new("cinder_hornet").amount(3).from_round(2))
```

<details>
<summary><b>Supported game versions</b></summary>

- 20260928-1336
- 20261007-1630

</details>

## Using this api as an developer

A mod is a folder in `GDPatch/mods/`:

```
GDPatch/mods/my_mod/
├── gdpatch_mod.toml                 id = "my_mod"
└── data/gdpatch/mods/my_mod/
    ├── mod.gd                       extends "res://avast/api/mod.gd"
    └── icon.png
```

GDPatch mounts `data/` over the game's files and creates a node from `mod.gd`. That node is your mod: every API module is a property on it.

| | |
| --- | --- |
| `events` | Subscribe to game events: kills, level ups, run start and end, bosses |
| `hooks` | Reach game scenes and nodes directly |
| `run` | Round, time, timers, pause, end the run |
| `player` | Health, experience, levels, coins |
| `stats` | Player stats, buffs, custom stats, lifetime counters |
| `enemies` | New enemies from game ones, abilities, spawning |
| `bosses` | New bosses with phases, the round 5 boss choice |
| `waves` | What the enemy spawner picks |
| `weapons` | New weapons and weapon upgrades |
| `upgrades` | Player stat upgrades offered on level up |
| `plugins` | Passive items with their own scripts |
| `drivers` | Weapon modifiers |
| `protocols` | Difficulty levels |
| `policies` | Run modifiers in the policy menu |
| `files` | Clickable files in the arena |
| `desktop` | Icons and folders on the desktop |
| `windows` | Desktop windows, popups, confirm dialogs, forms, in-run notices |
| `ui` | Toasts, speech bubbles, floating text, HUD widgets |
| `audio` | Sound effects and music |
| `appearance` | Wallpapers, themes, cursor |
| `locale` | Translations |
| `save` | Data stored in the player's profile |
| `mods` | Installed mods, their versions and problems |

Definitions are objects with chained setters (`Enemy.new("x").health(30)`), choices are enums (`Rarity.RARE`, `Corner.TOP_RIGHT`) and Built-in event names are constants on `Events`.

Full documentation lives in the AVaSt docs (coming soon.)