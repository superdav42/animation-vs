extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var progress = root.get_node("Progress")
	var original_mobile_mode: bool = progress.mobile_mode
	var original_equipped: Dictionary = progress.equipped.duplicate(true)
	progress.mobile_mode = false
	progress.equipped = {"vehicles": "board", "weapons": "dagger", "abilities": "vine", "skins": "classic"}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	_check(main.screen.get_child_count() > 0, "Home screen did not build")
	_check(GearCatalog.rough_weapon_ids().size() >= 3, "First-login weapon pool is not randomizable")
	main._show_customize()
	await process_frame
	_check(main.screen.get_child_count() > 0, "Customization screen did not build")
	for player_weapon_id in GearCatalog.WEAPONS:
		var generated := GearCatalog.build_cpu_loadout({"vehicles": "", "weapons": player_weapon_id, "abilities": ""})
		var player_tier: String = GearCatalog.item("weapons", player_weapon_id)["tier"]
		_check(generated["weapon_data"]["tier"] == player_tier, "CPU generation failed to match weapon tier %s" % player_tier)
		_check(generated["weapons"] != player_weapon_id, "CPU generation copied player weapon %s" % player_weapon_id)

	main._start_round()
	await process_frame
	var arena = main.screen.get_child(main.screen.get_child_count() - 1)
	_check(arena.player != null, "Round did not create a player")
	_check(arena.cpu != null, "Round did not create a CPU rival")
	_check(arena.player_health_bar.value == arena.player.max_health, "Player health HUD was not initialized")
	_check(arena.cpu_loadout["weapons"] != progress.equipped["weapons"], "CPU weapon was not different")
	_check(arena.cpu_loadout["weapon_data"]["tier"] == GearCatalog.item("weapons", progress.equipped["weapons"])["tier"], "CPU weapon tier did not match the player")
	_check(not arena.cpu_loadout["vehicles"].is_empty(), "CPU did not mirror the equipped vehicle slot")
	_check(not arena.cpu_loadout["abilities"].is_empty(), "CPU did not mirror the equipped ability slot")
	_check(arena.player.skin_shape == "round", "Player skin was not applied to the stick figure")
	_check(arena.cpu.skin_shape != arena.player.skin_shape, "CPU stick-figure skin copied the player's shape")

	arena.cpu.global_position = arena.player.global_position + Vector2.UP * 75.0
	arena.player.facing = Vector2.UP
	var cpu_health_before: float = arena.cpu.health
	arena._player_attack()
	_check(arena.cpu.health < cpu_health_before, "Player weapon did not damage the CPU")
	arena.cpu.weapon_id = "wrench"
	arena.cpu.weapon_data = GearCatalog.CPU_WEAPONS["wrench"]
	arena.cpu.global_position = arena.player.global_position + Vector2.UP * 75.0
	arena.player.invulnerable_time = 0.0
	var player_health_before: float = arena.player.health
	arena._cpu_attack()
	_check(arena.player.health < player_health_before, "CPU weapon did not damage the player")
	arena.cpu.ability_id = "frost"
	arena.cpu.ability_data = GearCatalog.CPU_ABILITIES["frost"]
	arena.player.invulnerable_time = 0.0
	player_health_before = arena.player.health
	arena._cpu_use_ability()
	_check(arena.player.health < player_health_before, "CPU ability did not damage the player")

	arena.ability_id = "vine"
	arena.ability_data = GearCatalog.item("abilities", "vine")
	arena._activate_player_ability()
	_check(arena.target_stage == 1, "Vine targeting did not start")
	_send_world_click(Vector2(105, 400))
	await process_frame
	_check(arena.target_stage == 2, "World input did not select the vine origin")
	_send_world_click(Vector2(560, 760))
	await process_frame
	_check(get_nodes_in_group("vines").size() == 1, "Vine was not created from two points")

	arena.finished = true
	main._show_results({"won": true, "result": "VICTORY", "score": 900, "damage": 88, "credits": 42, "cpu_loadout": arena.cpu_loadout})
	await process_frame
	_check(main.screen.get_child_count() > 0, "Results screen did not build")

	progress.mobile_mode = true
	progress.equipped = {"vehicles": "", "weapons": "dagger", "abilities": "", "skins": "classic"}
	main._start_round()
	await process_frame
	var mobile_arena = main.screen.get_child(main.screen.get_child_count() - 1)
	var touch_buttons: Array[Node] = mobile_arena.find_children("*", "Button", true, false)
	_check(touch_buttons.size() >= 7, "Mobile controls did not build")
	_check(not mobile_arena.player.keyboard_enabled, "Keyboard movement remained active in mobile mode")
	_check(mobile_arena.cpu_loadout["vehicles"].is_empty(), "CPU received a vehicle when the player went on foot")
	_check(mobile_arena.cpu_loadout["abilities"].is_empty(), "CPU received an ability when the player left the slot empty")
	mobile_arena.finished = true
	progress.mobile_mode = original_mobile_mode
	progress.equipped = original_equipped

	if failures.is_empty():
		print("SMOKE TEST PASS: Animation VS customization, stick fighters, matched CPU duel, optional gear, targeting, and mobile controls")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _send_world_click(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
