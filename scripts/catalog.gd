class_name GearCatalog
extends RefCounted

const TIER_COLORS := {
	"Rough": Color("#99a9ad"),
	"Good": Color("#62d6a4"),
	"Great": Color("#64a8ff"),
	"Legendary": Color("#ffb347"),
}

const TIER_DROP_WEIGHTS := {
	"Rough": 60.0,
	"Good": 25.0,
	"Great": 10.0,
	"Legendary": 3.0,
}

const ARENAS := {
	"neon_forest": {"name": "Neon Forest", "description": "Living branches, drifting spores, and a cool moonlit fighting lane.", "accent": Color("#43d9bd")},
	"moon_dojo": {"name": "Moon Dojo", "description": "A quiet mountain courtyard with lanterns, timber, and a giant moon.", "accent": Color("#ffd166")},
	"ember_foundry": {"name": "Ember Foundry", "description": "Furnaces, riveted steel, glowing vents, and slow showers of sparks.", "accent": Color("#ff704f")},
	"crystal_cavern": {"name": "Crystal Cavern", "description": "Layered stone, luminous crystal clusters, and drifting cave mist.", "accent": Color("#a889ff")},
}

const VEHICLES := {
	"board": {"name": "Scrap Board", "tier": "Rough", "cost": 0, "speed": 360.0, "armor": 0, "boost": 1.35, "texture": "rivets", "icon": "BOARD", "description": "Light, nimble, and held together with hope."},
	"bike": {"name": "Trail Bike", "tier": "Good", "cost": 140, "speed": 410.0, "armor": 10, "boost": 1.45, "texture": "trail", "icon": "BIKE", "description": "Quick turns and a little extra protection."},
	"buggy": {"name": "Neon Buggy", "tier": "Great", "cost": 360, "speed": 450.0, "armor": 25, "boost": 1.55, "texture": "grid", "icon": "BUGGY", "description": "Fast, sturdy, and impossible to miss."},
	"rocket": {"name": "Pocket Rocket", "tier": "Legendary", "cost": 850, "speed": 510.0, "armor": 40, "boost": 1.75, "texture": "flame", "icon": "ROCKET", "description": "A grounded rocket sled with enormous acceleration."},
}

const WEAPONS := {
	"dagger": {"name": "Rusty Dagger", "tier": "Rough", "cost": 0, "damage": 22.0, "cooldown": 0.48, "range": 105.0, "style": "melee", "texture": "rust", "icon": "DAGGER", "description": "A short-range slash. Reliable in a pinch."},
	"bat": {"name": "Battered Bat", "tier": "Rough", "cost": 35, "damage": 24.0, "cooldown": 0.58, "range": 118.0, "style": "melee", "texture": "tape", "icon": "BAT", "description": "A dented practice bat with a heavy swing."},
	"popgun": {"name": "Tin Popgun", "tier": "Rough", "cost": 40, "damage": 16.0, "cooldown": 0.7, "range": 540.0, "style": "projectile", "texture": "rivets", "icon": "POPGUN", "description": "A noisy starter blaster made from spare parts."},
	"bow": {"name": "Pulse Bow", "tier": "Good", "cost": 120, "damage": 28.0, "cooldown": 0.55, "range": 700.0, "style": "projectile", "texture": "pulse", "icon": "BOW", "description": "Launches quick bolts through the arena."},
	"blaster": {"name": "Arc Blaster", "tier": "Great", "cost": 330, "damage": 38.0, "cooldown": 0.34, "range": 800.0, "style": "projectile", "pierce": 2, "texture": "circuit", "icon": "BLASTER", "description": "Rapid electric shots that pierce two foes."},
	"flame": {"name": "Flamethrower", "tier": "Legendary", "cost": 780, "damage": 48.0, "cooldown": 0.28, "range": 235.0, "style": "flame", "texture": "heat", "icon": "FLAME", "description": "A wide cone of glorious, dangerous fire."},
}

const ABILITIES := {
	"ember": {"name": "Ember Pop", "tier": "Rough", "cost": 0, "cooldown": 5.0, "style": "burst", "icon": "EMBER", "description": "A hot shockwave that clears nearby enemies."},
	"vine": {"name": "Vine Weaver", "tier": "Good", "cost": 170, "cooldown": 7.0, "style": "vine", "icon": "VINE", "description": "Choose two points. A damaging vine grows between them."},
	"blink": {"name": "Phase Blink", "tier": "Great", "cost": 310, "cooldown": 4.0, "style": "blink", "icon": "BLINK", "description": "Teleport safely to the chosen point."},
	"flight": {"name": "Gravity Wings", "tier": "Great", "cost": 390, "cooldown": 0.0, "style": "flight", "icon": "WINGS", "description": "Hold jump in the air to fly; release it and gravity takes over."},
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
	"roller": {"name": "CPU Roller", "tier": "Rough", "speed": 350.0, "armor": 0, "boost": 1.32, "texture": "chevron"},
	"spring_cart": {"name": "Spring Cart", "tier": "Rough", "speed": 340.0, "armor": 4, "boost": 1.36, "texture": "springs"},
	"hoverbike": {"name": "CPU Hoverbike", "tier": "Good", "speed": 400.0, "armor": 10, "boost": 1.42, "texture": "vents"},
	"tread_cycle": {"name": "Tread Cycle", "tier": "Good", "speed": 390.0, "armor": 14, "boost": 1.4, "texture": "treads"},
	"mech": {"name": "CPU Walker", "tier": "Great", "speed": 430.0, "armor": 25, "boost": 1.5, "texture": "hazard"},
	"crab_tank": {"name": "Crab Tank", "tier": "Great", "speed": 420.0, "armor": 30, "boost": 1.46, "texture": "armor"},
	"saucer": {"name": "CPU Saucer", "tier": "Legendary", "speed": 485.0, "armor": 40, "boost": 1.65, "texture": "stars"},
	"meteor_pod": {"name": "Meteor Pod", "tier": "Legendary", "speed": 470.0, "armor": 46, "boost": 1.62, "texture": "cracked"},
}

const CPU_WEAPONS := {
	"wrench": {"name": "Bent Wrench", "tier": "Rough", "damage": 18.0, "cooldown": 0.62, "range": 108.0, "style": "melee"},
	"pebbler": {"name": "Pebble Slinger", "tier": "Rough", "damage": 15.0, "cooldown": 0.72, "range": 520.0, "style": "projectile"},
	"disc": {"name": "Disc Launcher", "tier": "Good", "damage": 24.0, "cooldown": 0.68, "range": 680.0, "style": "projectile"},
	"spear": {"name": "Volt Spear", "tier": "Good", "damage": 27.0, "cooldown": 0.72, "range": 138.0, "style": "melee"},
	"rail": {"name": "Mini Railgun", "tier": "Great", "damage": 32.0, "cooldown": 0.58, "range": 820.0, "style": "projectile", "pierce": 2},
	"shock_hammer": {"name": "Shock Hammer", "tier": "Great", "damage": 35.0, "cooldown": 0.7, "range": 128.0, "style": "melee"},
	"drone": {"name": "Drone Cannon", "tier": "Great", "damage": 27.0, "cooldown": 0.42, "range": 760.0, "style": "projectile"},
	"star_lance": {"name": "Star Lance", "tier": "Legendary", "damage": 42.0, "cooldown": 0.45, "range": 175.0, "style": "melee"},
	"plasma": {"name": "Plasma Sprayer", "tier": "Legendary", "damage": 38.0, "cooldown": 0.4, "range": 250.0, "style": "flame"},
}

const CPU_ABILITIES := {
	"frost": {"name": "Frost Ring", "tier": "Rough", "cooldown": 6.0, "style": "burst"},
	"skip_step": {"name": "Skip Step", "tier": "Rough", "cooldown": 7.0, "style": "blink"},
	"root_trap": {"name": "Root Trap", "tier": "Good", "cooldown": 8.0, "style": "vine"},
	"gust_pack": {"name": "Gust Pack", "tier": "Good", "cooldown": 0.0, "style": "flight"},
	"phase_step": {"name": "Phase Step", "tier": "Great", "cooldown": 5.0, "style": "blink"},
	"gravity_well": {"name": "Gravity Well", "tier": "Great", "cooldown": 7.0, "style": "burst"},
	"void_storm": {"name": "Void Storm", "tier": "Legendary", "cooldown": 10.0, "style": "inferno"},
	"star_wings": {"name": "Star Wings", "tier": "Legendary", "cooldown": 0.0, "style": "flight"},
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
	var cpu_weapon := _pick_cpu_item(CPU_WEAPONS, player_weapon.get("tier", "Rough"), player_weapon.get("style", ""))
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
		var cpu_vehicle := _pick_cpu_item(CPU_VEHICLES, player_vehicle.get("tier", "Rough"))
		result["vehicles"] = cpu_vehicle
		result["vehicle_data"] = CPU_VEHICLES[cpu_vehicle]
	var player_ability_id: String = player_loadout.get("abilities", "")
	if not player_ability_id.is_empty():
		var player_ability := item("abilities", player_ability_id)
		var cpu_ability := _pick_cpu_item(CPU_ABILITIES, player_ability.get("tier", "Rough"), player_ability.get("style", ""))
		result["abilities"] = cpu_ability
		result["ability_data"] = CPU_ABILITIES[cpu_ability]
	return result

static func random_gear_drop(owned_items: Dictionary, roll := -1.0) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var total_weight := 0.0
	for category in ["vehicles", "weapons", "abilities"]:
		for item_id in category_data(category):
			if item_id in owned_items.get(category, []):
				continue
			var data := item(category, item_id)
			var weight: float = TIER_DROP_WEIGHTS.get(data.get("tier", "Rough"), 1.0)
			candidates.append({"category": category, "item_id": item_id, "data": data, "weight": weight})
			total_weight += weight
	if candidates.is_empty():
		return {}
	var unit_roll: float = randf() if roll < 0.0 else clampf(roll, 0.0, 0.999999)
	var pick := unit_roll * total_weight
	for candidate in candidates:
		pick -= float(candidate["weight"])
		if pick <= 0.0:
			return candidate
	return candidates.back()

static func _pick_cpu_item(pool: Dictionary, tier: String, avoided_style := "") -> String:
	var candidates: Array[String] = []
	var different_style: Array[String] = []
	for item_id in pool:
		if pool[item_id].get("tier", "Rough") != tier:
			continue
		candidates.append(item_id)
		if avoided_style.is_empty() or pool[item_id].get("style", "") != avoided_style:
			different_style.append(item_id)
	if not different_style.is_empty():
		return different_style.pick_random()
	return candidates.pick_random()
