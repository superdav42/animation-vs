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
	progress.mobile_mode = false
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	_check(main.screen.get_child_count() > 0, "Home screen did not build")

	main._start_round()
	await process_frame
	var arena = main.screen.get_child(main.screen.get_child_count() - 1)
	_check(arena.player != null, "Round did not create a player")
	_check(arena.hud_health.value == arena.player.max_health, "Health HUD was not initialized")

	arena._spawn_enemy()
	await process_frame
	_check(get_nodes_in_group("enemies").size() >= 1, "Enemy spawning failed")

	arena.ability_id = "vine"
	arena.ability_data = GearCatalog.item("abilities", "vine")
	arena._activate_ability()
	_check(arena.vine_stage == 1, "Vine targeting did not start")
	_send_world_click(Vector2(105, 400))
	await process_frame
	_check(arena.vine_stage == 2, "World input did not select the vine origin")
	_send_world_click(Vector2(560, 760))
	await process_frame
	_check(get_nodes_in_group("vines").size() == 1, "Vine was not created from two points")

	arena.finished = true
	main._show_results({"survived": true, "score": 900, "kills": 6, "credits": 42, "wave": 3})
	await process_frame
	_check(main.screen.get_child_count() > 0, "Results screen did not build")

	progress.mobile_mode = true
	main._start_round()
	await process_frame
	var mobile_arena = main.screen.get_child(main.screen.get_child_count() - 1)
	var touch_buttons: Array[Node] = mobile_arena.find_children("*", "Button", true, false)
	_check(touch_buttons.size() >= 7, "Mobile controls did not build")
	_check(not mobile_arena.player.keyboard_enabled, "Keyboard movement remained active in mobile mode")
	mobile_arena.finished = true
	progress.mobile_mode = original_mobile_mode

	if failures.is_empty():
		print("SMOKE TEST PASS: menus, desktop/mobile arena, enemy, vine, and results")
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
