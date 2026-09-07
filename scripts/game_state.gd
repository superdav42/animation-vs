extends Node

signal changed

const SAVE_PATH := "user://animation_vs_progress.cfg"
const CATEGORIES := ["vehicles", "weapons", "abilities", "skins"]
const SAVE_VERSION := 2

var credits := 240
var mobile_mode := false
var best_score := 0
var player_color := "Mint"
var player_design := "classic"
var selected_arena := "moon_dojo"
var unlocked := {
	"vehicles": ["board"],
	"weapons": [],
	"abilities": ["ember"],
	"skins": ["classic"],
}
var equipped := {
	"vehicles": "",
	"weapons": "",
	"abilities": "",
	"skins": "classic",
}

func _ready() -> void:
	if not _load_progress():
		_create_new_profile()

func owns(category: String, item_id: String) -> bool:
	return item_id in unlocked.get(category, [])

func purchase(category: String, item_id: String) -> bool:
	var data := GearCatalog.item(category, item_id)
	if data.is_empty() or owns(category, item_id):
		return false
	var cost: int = data.get("cost", 0)
	if credits < cost:
		return false
	credits -= cost
	unlocked[category].append(item_id)
	_save_progress()
	changed.emit()
	return true

func equip(category: String, item_id: String) -> bool:
	if not owns(category, item_id):
		return false
	equipped[category] = item_id
	_save_progress()
	changed.emit()
	return true

func unequip(category: String) -> bool:
	if category not in ["vehicles", "abilities"]:
		return false
	equipped[category] = ""
	_save_progress()
	changed.emit()
	return true

func set_player_color(color_name: String) -> bool:
	if color_name not in GearCatalog.PLAYER_COLORS:
		return false
	player_color = color_name
	_save_progress()
	changed.emit()
	return true

func set_player_design(design_id: String) -> bool:
	if design_id not in GearCatalog.PLAYER_DESIGNS:
		return false
	player_design = design_id
	_save_progress()
	changed.emit()
	return true

func toggle_mobile_mode() -> void:
	mobile_mode = not mobile_mode
	_save_progress()
	changed.emit()

func finish_round(score: int, reward: int, chance_roll := -1.0, item_roll := -1.0) -> Dictionary:
	var outcome := {"credits": reward, "drop_category": "", "drop_id": "", "drop_data": {}}
	var drop_chance: float = randf() if chance_roll < 0.0 else chance_roll
	if drop_chance < 0.12:
		var drop := GearCatalog.random_gear_drop(unlocked, item_roll)
		if not drop.is_empty():
			var category: String = drop["category"]
			var item_id: String = drop["item_id"]
			unlocked[category].append(item_id)
			outcome = {"credits": 0, "drop_category": category, "drop_id": item_id, "drop_data": drop["data"]}
	credits += int(outcome["credits"])
	best_score = maxi(best_score, score)
	_save_progress()
	changed.emit()
	return outcome

func select_arena(arena_id: String) -> bool:
	if arena_id not in GearCatalog.ARENAS:
		return false
	selected_arena = arena_id
	_save_progress()
	changed.emit()
	return true

func reset_progress() -> void:
	_create_new_profile()
	changed.emit()

func _create_new_profile() -> void:
	credits = 240
	best_score = 0
	player_color = "Mint"
	player_design = "classic"
	selected_arena = "moon_dojo"
	var starter_options := GearCatalog.rough_weapon_ids()
	var starter_weapon: String = starter_options.pick_random()
	unlocked = {"vehicles": ["board"], "weapons": [starter_weapon], "abilities": ["ember"], "skins": ["classic"]}
	equipped = {"vehicles": "", "weapons": starter_weapon, "abilities": "", "skins": "classic"}
	_save_progress()

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "credits", credits)
	config.set_value("profile", "mobile_mode", mobile_mode)
	config.set_value("profile", "best_score", best_score)
	config.set_value("profile", "player_color", player_color)
	config.set_value("profile", "player_design", player_design)
	config.set_value("profile", "selected_arena", selected_arena)
	config.set_value("profile", "save_version", SAVE_VERSION)
	for category in CATEGORIES:
		config.set_value("inventory", category, unlocked[category])
		config.set_value("loadout", category, equipped[category])
	config.save(SAVE_PATH)

func _load_progress() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	credits = int(config.get_value("profile", "credits", credits))
	mobile_mode = bool(config.get_value("profile", "mobile_mode", mobile_mode))
	best_score = int(config.get_value("profile", "best_score", best_score))
	player_color = str(config.get_value("profile", "player_color", player_color))
	player_design = str(config.get_value("profile", "player_design", player_design))
	var save_version := int(config.get_value("profile", "save_version", 0))
	selected_arena = _migrated_arena(str(config.get_value("profile", "selected_arena", selected_arena)), save_version)
	for category in CATEGORIES:
		var saved_items: Array = config.get_value("inventory", category, unlocked[category])
		unlocked[category] = saved_items
		var saved_equipped: String = str(config.get_value("loadout", category, equipped[category]))
		if saved_equipped in saved_items or (saved_equipped.is_empty() and category in ["vehicles", "abilities"]):
			equipped[category] = saved_equipped
	return not equipped["weapons"].is_empty()

func _migrated_arena(saved_arena: String, save_version: int) -> String:
	if save_version < SAVE_VERSION or saved_arena not in GearCatalog.ARENAS:
		return "moon_dojo"
	return saved_arena
