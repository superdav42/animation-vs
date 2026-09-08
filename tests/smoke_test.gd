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
	var original_unlocked: Dictionary = progress.unlocked.duplicate(true)
	var original_credits: int = progress.credits
	var original_best_score: int = progress.best_score
	var original_arena: String = progress.selected_arena
	progress._create_new_profile()
	_check(progress.selected_arena == "moon_dojo", "New profiles do not start with the redesigned Moon Dojo backdrop")
	_check(progress._migrated_arena("neon_forest", 1) == "moon_dojo", "Existing profiles do not migrate from the former forest default")
	_check(progress._migrated_arena("crystal_cavern", 2) == "crystal_cavern", "Current profiles lose their deliberate arena selection")
	progress.mobile_mode = false
	progress.equipped = {"vehicles": "board", "weapons": "dagger", "abilities": "vine", "skins": "classic"}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	_check(main.screen.get_child_count() > 0, "Home screen did not build")
	_check(GearCatalog.rough_weapon_ids().size() >= 3, "First-login weapon pool is not randomizable")
	_check(GearCatalog.ARENAS.size() >= 4, "Selectable background catalog is incomplete")
	_check(GearCatalog.TIER_DROP_WEIGHTS["Rough"] > GearCatalog.TIER_DROP_WEIGHTS["Good"], "Rough drops are not more common than Good drops")
	_check(GearCatalog.TIER_DROP_WEIGHTS["Good"] > GearCatalog.TIER_DROP_WEIGHTS["Epic"], "Good drops are not more common than Epic drops")
	_check(GearCatalog.TIER_DROP_WEIGHTS["Epic"] > GearCatalog.TIER_DROP_WEIGHTS["Legendary"], "Epic drops are not more common than Legendary drops")
	var tier_minimums := {"Rough": 100, "Good": 450, "Epic": 1000, "Legendary": 1500}
	for category in ["vehicles", "weapons", "abilities", "skins"]:
		for item_id in GearCatalog.category_data(category):
			var item_data: Dictionary = GearCatalog.item(category, item_id)
			_check(int(item_data["cost"]) >= int(tier_minimums[item_data["tier"]]), "%s is priced below its %s tier minimum" % [item_data["name"], item_data["tier"]])
	for vehicle_id in GearCatalog.VEHICLES:
		var vehicle_data: Dictionary = GearCatalog.VEHICLES[vehicle_id]
		var matching_weapon_costs: Array[int] = []
		for priced_weapon_id in GearCatalog.WEAPONS:
			if GearCatalog.WEAPONS[priced_weapon_id]["tier"] == vehicle_data["tier"]:
				matching_weapon_costs.append(int(GearCatalog.WEAPONS[priced_weapon_id]["cost"]))
		_check(matching_weapon_costs.is_empty() or int(vehicle_data["cost"]) > matching_weapon_costs.max(), "%s does not cost more than its tier's weapons" % vehicle_data["name"])
	_check(bool(GearCatalog.VEHICLES["rocket"]["flight"]), "Pocket Rocket is not configured as a flyable vehicle")
	_check(float(GearCatalog.VEHICLES["buggy"]["speed"]) > float(GearCatalog.VEHICLES["bike"]["speed"]), "Neon Buggy is not faster than Trail Bike")
	main._show_customize()
	await process_frame
	_check(main.screen.get_child_count() > 0, "Customization screen did not build")
	for player_weapon_id in GearCatalog.WEAPONS:
		var generated := GearCatalog.build_cpu_loadout({"vehicles": "", "weapons": player_weapon_id, "abilities": ""})
		var player_tier: String = GearCatalog.item("weapons", player_weapon_id)["tier"]
		_check(generated["weapon_data"]["tier"] == player_tier, "CPU generation failed to match weapon tier %s" % player_tier)
		_check(generated["weapons"] != player_weapon_id, "CPU generation copied player weapon %s" % player_weapon_id)
		_check(generated["weapon_data"]["style"] != GearCatalog.item("weapons", player_weapon_id)["style"], "CPU weapon did not choose a visibly different combat style for %s" % player_weapon_id)

	for arena_id in GearCatalog.ARENAS:
		_check(progress.select_arena(arena_id), "Could not select arena %s" % arena_id)
		_check(progress.selected_arena == arena_id, "Arena selection did not persist in memory")
	progress.select_arena("moon_dojo")

	main._start_round()
	await process_frame
	var arena = main.screen.get_child(main.screen.get_child_count() - 1)
	_check(arena.player != null, "Round did not create a player")
	_check(arena.cpu != null, "Round did not create a CPU rival")
	_check(arena.player_health_bar.value == arena.player.max_health, "Player health HUD was not initialized")
	_check(arena.cpu_loadout["weapons"] != progress.equipped["weapons"], "CPU weapon was not different")
	_check(arena.cpu_loadout["weapon_data"]["tier"] == GearCatalog.item("weapons", progress.equipped["weapons"])["tier"], "CPU weapon tier did not match the player")
	_check(arena.cpu_loadout["weapon_data"]["style"] != GearCatalog.item("weapons", progress.equipped["weapons"])["style"], "CPU weapon style matched the player's style")
	_check(not arena.cpu_loadout["vehicles"].is_empty(), "CPU did not mirror the equipped vehicle slot")
	_check(not arena.cpu_loadout["abilities"].is_empty(), "CPU did not mirror the equipped ability slot")
	_check(arena.player.skin_shape == "round", "Player skin was not applied to the stick figure")
	_check(arena.cpu.skin_shape != arena.player.skin_shape, "CPU stick-figure skin copied the player's shape")
	_check(arena.arena_art.arena_id == "moon_dojo", "Selected background was not applied to the round")
	_check(is_equal_approx(arena.player.global_position.y, arena.arena_art.ground_y()), "Player did not start on the ground")
	arena.player.teleport_to(Vector2(300, 500))
	arena.player.set_mobile_vector(Vector2.ZERO)
	arena.player._physics_process(0.1)
	_check(arena.player.velocity.y > 0.0, "Gravity did not pull a teleported player down")
	arena.player.global_position.y = arena.arena_art.ground_y()
	arena.player.can_fly = false
	arena.player.set_mobile_vector(Vector2.UP)
	arena.player._physics_process(0.1)
	_check(is_equal_approx(arena.player.global_position.y, arena.arena_art.ground_y()), "A player without flight left the ground")
	arena.player.can_fly = true
	arena.player.set_mobile_vector(Vector2.UP)
	arena.player._physics_process(0.1)
	_check(arena.player.velocity.y < 0.0, "Gravity Wings did not enable upward flight")
	arena.player.can_fly = false
	arena.player.set_mobile_vector(Vector2.ZERO)
	var rocket_tester = load("res://scenes/player.tscn").instantiate()
	root.add_child(rocket_tester)
	rocket_tester.configure(GearCatalog.VEHICLES["rocket"], "rocket", GearCatalog.SKINS["classic"], Color("#63e6bc"), "classic", "dagger", {})
	rocket_tester.global_position = Vector2(360, arena.arena_art.ground_y() - 120.0)
	rocket_tester.set_mobile_vector(Vector2.UP)
	rocket_tester._physics_process(0.1)
	_check(rocket_tester.vehicle_can_fly and rocket_tester.velocity.y < 0.0, "Pocket Rocket thrust did not lift the fighter")
	rocket_tester.global_position = Vector2(360, arena.arena_art.ground_y())
	rocket_tester.set_mobile_vector(Vector2.RIGHT)
	_check(rocket_tester.try_boost(), "Pocket Rocket boost did not activate")
	rocket_tester._physics_process(0.05)
	_check(rocket_tester.velocity.x > float(GearCatalog.VEHICLES["buggy"]["speed"]), "Pocket Rocket boost did not produce a visible speed advantage")
	rocket_tester.queue_free()

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
	_check(touch_buttons.size() >= 4, "Large mobile action controls did not build")
	_check(not mobile_arena.player.keyboard_enabled, "Keyboard movement remained active in mobile mode")
	_check(mobile_arena.cpu_loadout["vehicles"].is_empty(), "CPU received a vehicle when the player went on foot")
	_check(mobile_arena.cpu_loadout["abilities"].is_empty(), "CPU received an ability when the player left the slot empty")
	var joysticks: Array[Node] = mobile_arena.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node.get_script() == mobile_arena.JoystickScript)
	_check(joysticks.size() == 1, "Mobile mode did not create one floating joystick")
	var mobile_jump_buttons := touch_buttons.filter(func(button: Button) -> bool: return button.text == "JUMP")
	_check(mobile_jump_buttons.size() == 1, "Mobile mode did not create a dedicated JUMP button")
	mobile_arena._jump_fighter(1)
	mobile_arena.player._physics_process(0.05)
	_check(mobile_arena.player.velocity.y < 0.0, "The mobile JUMP button did not launch a grounded fighter")
	_check(mobile_arena.player.global_position.y < mobile_arena.arena_art.ground_y(), "Jumping did not lift the fighter above the floor")
	var attack_buttons := touch_buttons.filter(func(button: Button) -> bool: return button.text == "ATTACK")
	_check(attack_buttons.size() == 1 and attack_buttons[0].size.x >= 110.0, "Mobile attack control is not large enough")
	mobile_arena.finished = true

	progress.mobile_mode = false
	progress.unlocked = {"vehicles": ["board", "rocket"], "weapons": ["dagger", "bow"], "abilities": ["ember"], "skins": ["classic"]}
	main._show_multiplayer_setup()
	await process_frame
	var setup_buttons: Array[Node] = main.screen.find_children("*", "Button", true, false)
	_check(setup_buttons.any(func(button: Button) -> bool: return button.text.contains("PLAYER 2") or button.text.contains("START FACE-TO-FACE")), "Multiplayer did not open the Player 2 gear setup")
	main._set_multiplayer_item("vehicles", "buggy")
	_check(main.multiplayer_loadout["vehicles"].is_empty(), "Player 2 could select a vehicle that was not purchased")
	main._set_multiplayer_item("weapons", "bow")
	await process_frame
	main._set_multiplayer_item("vehicles", "rocket")
	await process_frame
	main._set_multiplayer_item("abilities", "")
	await process_frame
	main._start_round("multiplayer")
	await process_frame
	var multiplayer_arena = main.screen.get_child(main.screen.get_child_count() - 1)
	_check(multiplayer_arena.game_mode == "multiplayer", "Multiplayer mode did not start")
	_check(multiplayer_arena.cpu.human_controlled, "Player 2 remained under CPU control")
	_check(multiplayer_arena.cpu.weapon_id == "bow", "Player 2's chosen owned weapon was not used")
	_check(multiplayer_arena.cpu.vehicle_id == "rocket", "Player 2's chosen owned vehicle was not used")
	_check(multiplayer_arena.cpu.ability_id.is_empty(), "Player 2 could not leave the optional ability slot empty")
	_check(multiplayer_arena.cpu.inverted_gravity, "Player 2 does not use upside-down gravity")
	_check(is_equal_approx(absf(multiplayer_arena.cpu.rotation), PI), "Player 2 stick figure was not rotated upside down")
	_check(is_equal_approx(multiplayer_arena.cpu.global_position.y, multiplayer_arena.arena_art.top_ground_y()), "Player 2 did not start on the top platform")
	_check(multiplayer_arena.cpu.global_position.y < multiplayer_arena.get_viewport_rect().size.y * 0.5, "Player 2 spawned in the bottom half of the screen")
	_check(multiplayer_arena._player_attack_direction().y < -0.5, "Player 1 attacks do not aim toward the top-side opponent")
	var multiplayer_joysticks: Array[Node] = multiplayer_arena.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node.get_script() == multiplayer_arena.JoystickScript)
	_check(multiplayer_joysticks.size() == 2, "Multiplayer did not create two floating joysticks")
	var multiplayer_jump_buttons: Array[Node] = multiplayer_arena.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.text == "JUMP")
	_check(multiplayer_jump_buttons.size() == 2, "Multiplayer did not create a JUMP button for each fighter")
	var upside_down_controls: Array[Node] = multiplayer_arena.find_children("*", "Control", true, false).filter(func(node: Control) -> bool: return is_equal_approx(absf(node.rotation), PI))
	_check(not upside_down_controls.is_empty(), "Player 2 controls were not rotated for face-to-face play")
	multiplayer_arena._set_joystick_vector(Vector2(0.75, -0.5), 2)
	_check(multiplayer_arena.cpu.mobile_vector.is_equal_approx(Vector2(-0.75, 0.5)), "Player 2 movement controls were not inverted into screen space")
	multiplayer_arena._jump_fighter(2)
	multiplayer_arena.cpu._physics_process(0.05)
	_check(multiplayer_arena.cpu.velocity.y > 0.0, "Top-side Player 2 did not jump downward into the arena")
	_check(multiplayer_arena.cpu.global_position.y > multiplayer_arena.arena_art.top_ground_y(), "Top-side Player 2 remained stuck to the upper platform")
	multiplayer_arena.finished = true

	progress.unlocked = {"vehicles": ["board"], "weapons": ["dagger"], "abilities": ["ember"], "skins": ["classic"]}
	var drop_reward: Dictionary = progress.finish_round(100, 75, 0.0, 0.999)
	_check(drop_reward["credits"] == 0, "Gear drop did not replace the parts reward")
	_check(not drop_reward["drop_id"].is_empty(), "Low-chance reward did not unlock gear")
	_check(drop_reward["drop_data"]["tier"] == "Legendary", "Highest roll did not reach the rarest available tier")
	var parts_reward: Dictionary = progress.finish_round(100, 75, 0.99, 0.0)
	_check(parts_reward["credits"] == 75 and parts_reward["drop_id"].is_empty(), "Normal parts reward was not preserved")

	progress.mobile_mode = original_mobile_mode
	progress.equipped = original_equipped
	progress.unlocked = original_unlocked
	progress.credits = original_credits
	progress.best_score = original_best_score
	progress.selected_arena = original_arena
	progress._save_progress()

	if failures.is_empty():
		print("SMOKE TEST PASS: tier pricing, functional vehicles, owned Player 2 loadouts, inverted top-side multiplayer, richer graphics, and grounded jumping")
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
