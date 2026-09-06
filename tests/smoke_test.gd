extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
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
	arena._handle_world_tap(Vector2(105, 400))
	arena._handle_world_tap(Vector2(560, 760))
	_check(get_nodes_in_group("vines").size() == 1, "Vine was not created from two points")

	arena.finished = true
	main._show_results({"survived": true, "score": 900, "kills": 6, "credits": 42, "wave": 3})
	await process_frame
	_check(main.screen.get_child_count() > 0, "Results screen did not build")

	if failures.is_empty():
		print("SMOKE TEST PASS: menus, arena, enemy, vine, and results")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
