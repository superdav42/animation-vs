extends Node

signal changed

const SAVE_PATH := "user://henrys_game_progress.cfg"
const CATEGORIES := ["vehicles", "weapons", "abilities"]

var credits := 240
var mobile_mode := false
var best_score := 0
var unlocked := {
	"vehicles": ["board"],
	"weapons": ["dagger"],
	"abilities": ["ember"],
}
var equipped := {
	"vehicles": "board",
	"weapons": "dagger",
	"abilities": "ember",
}

func _ready() -> void:
	_load_progress()

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

func toggle_mobile_mode() -> void:
	mobile_mode = not mobile_mode
	_save_progress()
	changed.emit()

func finish_round(score: int, reward: int) -> void:
	credits += reward
	best_score = maxi(best_score, score)
	_save_progress()
	changed.emit()

func reset_progress() -> void:
	credits = 240
	best_score = 0
	unlocked = {"vehicles": ["board"], "weapons": ["dagger"], "abilities": ["ember"]}
	equipped = {"vehicles": "board", "weapons": "dagger", "abilities": "ember"}
	_save_progress()
	changed.emit()

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "credits", credits)
	config.set_value("profile", "mobile_mode", mobile_mode)
	config.set_value("profile", "best_score", best_score)
	for category in CATEGORIES:
		config.set_value("inventory", category, unlocked[category])
		config.set_value("loadout", category, equipped[category])
	config.save(SAVE_PATH)

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	credits = int(config.get_value("profile", "credits", credits))
	mobile_mode = bool(config.get_value("profile", "mobile_mode", mobile_mode))
	best_score = int(config.get_value("profile", "best_score", best_score))
	for category in CATEGORIES:
		var saved_items: Array = config.get_value("inventory", category, unlocked[category])
		unlocked[category] = saved_items
		var saved_equipped: String = str(config.get_value("loadout", category, equipped[category]))
		if saved_equipped in saved_items:
			equipped[category] = saved_equipped
