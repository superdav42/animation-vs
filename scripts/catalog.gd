class_name GearCatalog
extends RefCounted

const TIER_COLORS := {
	"Rough": Color("#99a9ad"),
	"Good": Color("#62d6a4"),
	"Great": Color("#64a8ff"),
	"Legendary": Color("#ffb347"),
}

const VEHICLES := {
	"board": {"name": "Scrap Board", "tier": "Rough", "cost": 0, "speed": 360.0, "armor": 0, "boost": 1.35, "icon": "BOARD", "description": "Light, nimble, and held together with hope."},
	"bike": {"name": "Trail Bike", "tier": "Good", "cost": 140, "speed": 410.0, "armor": 10, "boost": 1.45, "icon": "BIKE", "description": "Quick turns and a little extra protection."},
	"buggy": {"name": "Neon Buggy", "tier": "Great", "cost": 360, "speed": 450.0, "armor": 25, "boost": 1.55, "icon": "BUGGY", "description": "Fast, sturdy, and impossible to miss."},
	"rocket": {"name": "Pocket Rocket", "tier": "Legendary", "cost": 850, "speed": 510.0, "armor": 40, "boost": 1.75, "icon": "ROCKET", "description": "A tiny starship with enormous acceleration."},
}

const WEAPONS := {
	"dagger": {"name": "Rusty Dagger", "tier": "Rough", "cost": 0, "damage": 22.0, "cooldown": 0.48, "range": 105.0, "style": "melee", "icon": "DAGGER", "description": "A short-range slash. Reliable in a pinch."},
	"bat": {"name": "Battered Bat", "tier": "Rough", "cost": 35, "damage": 24.0, "cooldown": 0.58, "range": 118.0, "style": "melee", "icon": "BAT", "description": "A dented practice bat with a heavy swing."},
	"popgun": {"name": "Tin Popgun", "tier": "Rough", "cost": 40, "damage": 16.0, "cooldown": 0.7, "range": 540.0, "style": "projectile", "icon": "POPGUN", "description": "A noisy starter blaster made from spare parts."},
	"bow": {"name": "Pulse Bow", "tier": "Good", "cost": 120, "damage": 28.0, "cooldown": 0.55, "range": 700.0, "style": "projectile", "icon": "BOW", "description": "Launches quick bolts through the arena."},
	"blaster": {"name": "Arc Blaster", "tier": "Great", "cost": 330, "damage": 38.0, "cooldown": 0.34, "range": 800.0, "style": "projectile", "pierce": 2, "icon": "BLASTER", "description": "Rapid electric shots that pierce two foes."},
	"flame": {"name": "Flamethrower", "tier": "Legendary", "cost": 780, "damage": 48.0, "cooldown": 0.28, "range": 235.0, "style": "flame", "icon": "FLAME", "description": "A wide cone of glorious, dangerous fire."},
}

const ABILITIES := {
	"ember": {"name": "Ember Pop", "tier": "Rough", "cost": 0, "cooldown": 5.0, "style": "burst", "icon": "EMBER", "description": "A hot shockwave that clears nearby enemies."},
	"vine": {"name": "Vine Weaver", "tier": "Good", "cost": 170, "cooldown": 7.0, "style": "vine", "icon": "VINE", "description": "Choose two points. A damaging vine grows between them."},
	"blink": {"name": "Phase Blink", "tier": "Great", "cost": 310, "cooldown": 4.0, "style": "blink", "icon": "BLINK", "description": "Teleport safely to the chosen point."},
	"inferno": {"name": "Solar Inferno", "tier": "Legendary", "cost": 720, "cooldown": 9.0, "style": "inferno", "icon": "INFERNO", "description": "Ignite almost everything visible at once."},
}

const SKINS := {
	"classic": {"name": "Classic Lines", "tier": "Rough", "cost": 0, "icon": "CLASSIC", "shape": "round", "description": "The clean original stick-fighter silhouette."},
	"street": {"name": "Street Runner", "tier": "Good", "cost": 110, "icon": "STREET", "shape": "cap", "description": "A backwards cap and quick-motion streaks."},
	"ninja": {"name": "Shadow Ninja", "tier": "Great", "cost": 280, "icon": "NINJA", "shape": "hood", "description": "A sharp hood, face wrap, and trailing scarf."},
	"robot": {"name": "Frame Bot", "tier": "Great", "cost": 360, "icon": "ROBOT", "shape": "square", "description": "A square head and segmented mechanical limbs."},
	"cosmic": {"name": "Cosmic Orbit", "tier": "Legendary", "cost": 760, "icon": "COSMIC", "shape": "orbit", "description": "A star-bright head with a tiny orbiting moon."},
}

const PLAYER_COLORS := {
	"Mint": Color("#63e6bc"),
	"Sky": Color("#68b7ff"),
	"Gold": Color("#ffd166"),
	"Coral": Color("#ff7b72"),
	"Violet": Color("#b48cff"),
	"White": Color("#f4f0dc"),
}

const PLAYER_DESIGNS := {
	"classic": "Clean",
	"visor": "Visor",
	"bolt": "Bolt",
}

const CPU_VEHICLES := {
	"roller": {"name": "CPU Roller", "tier": "Rough", "speed": 350.0, "armor": 0, "boost": 1.32},
	"hoverbike": {"name": "CPU Hoverbike", "tier": "Good", "speed": 400.0, "armor": 10, "boost": 1.42},
	"mech": {"name": "CPU Walker", "tier": "Great", "speed": 430.0, "armor": 25, "boost": 1.5},
	"saucer": {"name": "CPU Saucer", "tier": "Legendary", "speed": 485.0, "armor": 40, "boost": 1.65},
}

const CPU_WEAPONS := {
	"wrench": {"name": "Bent Wrench", "tier": "Rough", "damage": 18.0, "cooldown": 0.62, "range": 108.0, "style": "melee"},
	"pebbler": {"name": "Pebble Slinger", "tier": "Rough", "damage": 15.0, "cooldown": 0.72, "range": 520.0, "style": "projectile"},
	"disc": {"name": "Disc Launcher", "tier": "Good", "damage": 24.0, "cooldown": 0.68, "range": 680.0, "style": "projectile"},
	"spear": {"name": "Volt Spear", "tier": "Good", "damage": 27.0, "cooldown": 0.72, "range": 138.0, "style": "melee"},
	"rail": {"name": "Mini Railgun", "tier": "Great", "damage": 32.0, "cooldown": 0.58, "range": 820.0, "style": "projectile", "pierce": 2},
	"drone": {"name": "Drone Cannon", "tier": "Great", "damage": 27.0, "cooldown": 0.42, "range": 760.0, "style": "projectile"},
	"star_lance": {"name": "Star Lance", "tier": "Legendary", "damage": 42.0, "cooldown": 0.45, "range": 175.0, "style": "melee"},
	"plasma": {"name": "Plasma Sprayer", "tier": "Legendary", "damage": 38.0, "cooldown": 0.4, "range": 250.0, "style": "flame"},
}

const CPU_ABILITIES := {
	"frost": {"name": "Frost Ring", "tier": "Rough", "cooldown": 6.0, "style": "burst"},
	"root_trap": {"name": "Root Trap", "tier": "Good", "cooldown": 8.0, "style": "vine"},
	"phase_step": {"name": "Phase Step", "tier": "Great", "cooldown": 5.0, "style": "blink"},
	"void_storm": {"name": "Void Storm", "tier": "Legendary", "cooldown": 10.0, "style": "inferno"},
}

static func category_data(category: String) -> Dictionary:
	match category:
		"vehicles": return VEHICLES
		"weapons": return WEAPONS
		"abilities": return ABILITIES
		"skins": return SKINS
	return {}

static func item(category: String, item_id: String) -> Dictionary:
	return category_data(category).get(item_id, {})

static func tier_color(tier: String) -> Color:
	return TIER_COLORS.get(tier, Color.WHITE)

static func rough_weapon_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in WEAPONS:
		if WEAPONS[item_id]["tier"] == "Rough":
			result.append(item_id)
	return result

static func build_cpu_loadout(player_loadout: Dictionary) -> Dictionary:
	var player_weapon: Dictionary = item("weapons", player_loadout.get("weapons", "dagger"))
	var weapon_candidates: Array[String] = []
	for item_id in CPU_WEAPONS:
		if CPU_WEAPONS[item_id]["tier"] == player_weapon.get("tier", "Rough"):
			weapon_candidates.append(item_id)
	var cpu_weapon: String = weapon_candidates.pick_random()
	var result := {
		"weapons": cpu_weapon,
		"weapon_data": CPU_WEAPONS[cpu_weapon],
		"vehicles": "",
		"vehicle_data": {},
		"abilities": "",
		"ability_data": {},
	}
	var player_vehicle_id: String = player_loadout.get("vehicles", "")
	if not player_vehicle_id.is_empty():
		var player_vehicle := item("vehicles", player_vehicle_id)
		for item_id in CPU_VEHICLES:
			if CPU_VEHICLES[item_id]["tier"] == player_vehicle.get("tier", "Rough"):
				result["vehicles"] = item_id
				result["vehicle_data"] = CPU_VEHICLES[item_id]
				break
	var player_ability_id: String = player_loadout.get("abilities", "")
	if not player_ability_id.is_empty():
		var player_ability := item("abilities", player_ability_id)
		for item_id in CPU_ABILITIES:
			if CPU_ABILITIES[item_id]["tier"] == player_ability.get("tier", "Rough"):
				result["abilities"] = item_id
				result["ability_data"] = CPU_ABILITIES[item_id]
				break
	return result
