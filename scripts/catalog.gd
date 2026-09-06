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
	"dagger": {"name": "Rusty Dagger", "tier": "Rough", "cost": 0, "damage": 22.0, "cooldown": 0.48, "range": 105.0, "icon": "DAGGER", "description": "A short-range slash. Reliable in a pinch."},
	"bow": {"name": "Pulse Bow", "tier": "Good", "cost": 120, "damage": 28.0, "cooldown": 0.55, "range": 700.0, "icon": "BOW", "description": "Launches quick bolts through the arena."},
	"blaster": {"name": "Arc Blaster", "tier": "Great", "cost": 330, "damage": 38.0, "cooldown": 0.34, "range": 800.0, "icon": "BLASTER", "description": "Rapid electric shots that pierce two foes."},
	"flame": {"name": "Flamethrower", "tier": "Legendary", "cost": 780, "damage": 48.0, "cooldown": 0.28, "range": 235.0, "icon": "FLAME", "description": "A wide cone of glorious, dangerous fire."},
}

const ABILITIES := {
	"ember": {"name": "Ember Pop", "tier": "Rough", "cost": 0, "cooldown": 5.0, "icon": "EMBER", "description": "A hot shockwave that clears nearby enemies."},
	"vine": {"name": "Vine Weaver", "tier": "Good", "cost": 170, "cooldown": 7.0, "icon": "VINE", "description": "Choose two points. A damaging vine grows between them."},
	"blink": {"name": "Phase Blink", "tier": "Great", "cost": 310, "cooldown": 4.0, "icon": "BLINK", "description": "Teleport safely to the chosen point."},
	"inferno": {"name": "Solar Inferno", "tier": "Legendary", "cost": 720, "cooldown": 9.0, "icon": "INFERNO", "description": "Ignite almost everything visible at once."},
}

static func category_data(category: String) -> Dictionary:
	match category:
		"vehicles": return VEHICLES
		"weapons": return WEAPONS
		"abilities": return ABILITIES
	return {}

static func item(category: String, item_id: String) -> Dictionary:
	return category_data(category).get(item_id, {})

static func tier_color(tier: String) -> Color:
	return TIER_COLORS.get(tier, Color.WHITE)
