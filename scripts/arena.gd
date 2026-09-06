extends Node2D

signal round_finished(summary: Dictionary)

const PlayerScene := preload("res://scenes/player.tscn")
const EnemyScript := preload("res://scripts/enemy.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const VineScript := preload("res://scripts/vine.gd")
const ArenaArtScript := preload("res://scripts/arena_art.gd")

const ROUND_LENGTH := 60.0

var player: CharacterBody2D
var arena_art: Node2D
var hud_score: Label
var hud_timer: Label
var hud_wave: Label
var hud_health: ProgressBar
var hud_power: Label
var hint_label: Label
var time_left := ROUND_LENGTH
var spawn_clock := 0.0
var attack_clock := 0.0
var ability_clock := 0.0
var kills := 0
var earned_credits := 0
var wave := 1
var mobile_attack := false
var vine_stage := 0
var vine_start := Vector2.ZERO
var aim_position := Vector2.ZERO
var finished := false
var weapon_id := "dagger"
var ability_id := "ember"
var weapon_data: Dictionary
var ability_data: Dictionary

func _ready() -> void:
	randomize()
	arena_art = ArenaArtScript.new()
	arena_art.z_index = -10
	add_child(arena_art)

	weapon_id = Progress.equipped["weapons"]
	ability_id = Progress.equipped["abilities"]
	weapon_data = GearCatalog.item("weapons", weapon_id)
	ability_data = GearCatalog.item("abilities", ability_id)

	player = PlayerScene.instantiate()
	player.global_position = get_viewport_rect().size * Vector2(0.5, 0.64)
	player.keyboard_enabled = not Progress.mobile_mode
	player.health_changed.connect(_on_health_changed)
	player.defeated.connect(_finish_round.bind(false))
	add_child(player)
	aim_position = player.global_position + Vector2.UP * 200.0
	_build_hud()
	player.configure(GearCatalog.item("vehicles", Progress.equipped["vehicles"]), Progress.equipped["vehicles"])
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(0.0, time_left - delta)
	spawn_clock -= delta
	attack_clock = maxf(0.0, attack_clock - delta)
	ability_clock = maxf(0.0, ability_clock - delta)
	wave = mini(8, 1 + int((ROUND_LENGTH - time_left) / 8.0))
	if spawn_clock <= 0.0:
		_spawn_enemy()
		spawn_clock = maxf(0.34, 1.2 - wave * 0.09)
	if (mobile_attack or (not Progress.mobile_mode and Input.is_action_pressed("attack"))) and vine_stage == 0:
		_attack()
	if not Progress.mobile_mode and Input.is_action_just_pressed("ability"):
		_activate_ability()
	if not Progress.mobile_mode and Input.is_action_just_pressed("boost"):
		_boost()
	_check_projectile_hits()
	_update_hud()
	if time_left <= 0.0:
		_finish_round(true)

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseMotion:
		aim_position = event.position
		player.set_aim(aim_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		aim_position = event.position
		player.set_aim(aim_position)
		_handle_world_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		aim_position = event.position
		player.set_aim(aim_position)
		_handle_world_tap(event.position)
	if event.is_action_pressed("ui_cancel"):
		_finish_round(false)

func _handle_world_tap(point: Vector2) -> void:
	if vine_stage == 1:
		vine_start = arena_art.snap_vine_start(point)
		vine_stage = 2
		hint_label.text = "VINE READY  •  TAP ITS DESTINATION"
	elif vine_stage == 2:
		_create_vine(vine_start, point)
		vine_stage = 0
		ability_clock = float(ability_data.get("cooldown", 7.0))
		hint_label.text = ""
	elif vine_stage == 3:
		_spawn_ring(player.global_position, Color("#8e85ff"), 70.0)
		player.teleport_to(point)
		_spawn_ring(player.global_position, Color("#8e85ff"), 70.0)
		vine_stage = 0
		ability_clock = float(ability_data.get("cooldown", 4.0))
		hint_label.text = ""

func _attack() -> void:
	if attack_clock > 0.0:
		return
	attack_clock = float(weapon_data.get("cooldown", 0.45))
	var direction: Vector2 = player.facing
	if weapon_id == "dagger":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var to_enemy: Vector2 = player.global_position.direction_to(enemy.global_position)
			if player.global_position.distance_to(enemy.global_position) <= float(weapon_data["range"]) and direction.dot(to_enemy) > 0.15:
				enemy.take_damage(float(weapon_data["damage"]))
		_spawn_slash(direction)
	elif weapon_id == "flame":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var distance: float = player.global_position.distance_to(enemy.global_position)
			var to_enemy: Vector2 = player.global_position.direction_to(enemy.global_position)
			if distance <= float(weapon_data["range"]) and direction.dot(to_enemy) > 0.55:
				enemy.take_damage(float(weapon_data["damage"]))
		_spawn_flame(direction)
	else:
		var projectile := ProjectileScript.new()
		projectile.global_position = player.global_position + direction * 38.0
		projectile.setup(direction, weapon_data, weapon_id)
		add_child(projectile)

func _activate_ability() -> void:
	if ability_clock > 0.0 or vine_stage > 0:
		return
	match ability_id:
		"ember":
			_damage_radius(player.global_position, 190.0, 45.0)
			_spawn_ring(player.global_position, Color("#ff784b"), 190.0)
			ability_clock = float(ability_data["cooldown"])
		"vine":
			vine_stage = 1
			hint_label.text = "VINE WEAVER  •  TAP GROUND OR A BRANCH"
		"blink":
			vine_stage = 3
			hint_label.text = "PHASE BLINK  •  TAP YOUR DESTINATION"
		"inferno":
			_damage_radius(player.global_position, 1000.0, 110.0)
			_spawn_ring(player.global_position, Color("#ffbc45"), 720.0)
			ability_clock = float(ability_data["cooldown"])

func _boost() -> void:
	if player.try_boost():
		_spawn_ring(player.global_position, Color("#4fe2cc"), 90.0)

func _create_vine(from: Vector2, to: Vector2) -> void:
	var vine := VineScript.new()
	vine.setup(from, to, 62.0)
	add_child(vine)

func _damage_radius(center: Vector2, radius: float, damage: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if center.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(damage)

func _spawn_enemy() -> void:
	var size := get_viewport_rect().size
	var side := randi() % 4
	var position := Vector2.ZERO
	match side:
		0: position = Vector2(58, randf_range(165, size.y - 130))
		1: position = Vector2(size.x - 58, randf_range(165, size.y - 130))
		2: position = Vector2(randf_range(70, size.x - 70), 155)
		3: position = Vector2(randf_range(70, size.x - 70), size.y - 120)
	var enemy := EnemyScript.new()
	enemy.global_position = position
	enemy.configure(wave, player)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _check_projectile_hits() -> void:
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
			continue
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and projectile.global_position.distance_to(enemy.global_position) < 35.0:
				projectile.hit(enemy)
				if projectile.is_queued_for_deletion():
					break

func _on_enemy_died(reward: int, at_position: Vector2) -> void:
	kills += 1
	earned_credits += reward
	_spawn_ring(at_position, Color("#f6df69"), 46.0)

func _on_health_changed(current: float, maximum: float) -> void:
	if hud_health:
		hud_health.max_value = maximum
		hud_health.value = current

func _finish_round(survived: bool) -> void:
	if finished:
		return
	finished = true
	var elapsed := ROUND_LENGTH - time_left
	var score := kills * 100 + int(elapsed) * 10
	var bonus := 60 + wave * 8 if survived else 15
	var reward := earned_credits + bonus
	round_finished.emit({"survived": survived, "score": score, "kills": kills, "credits": reward, "wave": wave})

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(22, 20)
	top_panel.size = Vector2(get_viewport_rect().size.x - 44, 104)
	top_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.08, 0.11, 0.94), Color("#286957"), 2, 22))
	root.add_child(top_panel)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	top_panel.add_child(top)
	for property in [["hud_score", "KILLS  0"], ["hud_timer", "1:00"], ["hud_wave", "WAVE  1"]]:
		var label := Label.new()
		label.text = property[1]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		top.add_child(label)
		set(property[0], label)

	hud_health = ProgressBar.new()
	hud_health.position = Vector2(36, 130)
	hud_health.size = Vector2(get_viewport_rect().size.x - 72, 20)
	hud_health.show_percentage = false
	hud_health.add_theme_stylebox_override("background", _box(Color("#152c34"), Color.TRANSPARENT, 0, 9))
	hud_health.add_theme_stylebox_override("fill", _box(Color("#5ce39e"), Color.TRANSPARENT, 0, 9))
	root.add_child(hud_health)

	hud_power = Label.new()
	hud_power.position = Vector2(32, 158)
	hud_power.size = Vector2(get_viewport_rect().size.x - 64, 34)
	hud_power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_power.add_theme_font_size_override("font_size", 17)
	hud_power.add_theme_color_override("font_color", Color("#a9c9c5"))
	root.add_child(hud_power)

	hint_label = Label.new()
	hint_label.position = Vector2(30, get_viewport_rect().size.y * 0.2)
	hint_label.size = Vector2(get_viewport_rect().size.x - 60, 70)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.add_theme_color_override("font_color", Color("#b8ff8b"))
	root.add_child(hint_label)

	var exit := Button.new()
	exit.text = "×"
	exit.position = Vector2(get_viewport_rect().size.x - 76, 31)
	exit.size = Vector2(42, 42)
	exit.add_theme_font_size_override("font_size", 25)
	exit.pressed.connect(_finish_round.bind(false))
	root.add_child(exit)

	if Progress.mobile_mode:
		_build_touch_controls(root)

func _build_touch_controls(root: Control) -> void:
	var size := get_viewport_rect().size
	var center := Vector2(138, size.y - 170)
	var up := _touch_button("▲", center + Vector2(-33, -95), Vector2(66, 66))
	var down := _touch_button("▼", center + Vector2(-33, 35), Vector2(66, 66))
	var left := _touch_button("◀", center + Vector2(-98, -30), Vector2(66, 66))
	var right := _touch_button("▶", center + Vector2(32, -30), Vector2(66, 66))
	for button in [up, down, left, right]: root.add_child(button)
	up.button_down.connect(_set_mobile_direction.bind(Vector2.UP))
	down.button_down.connect(_set_mobile_direction.bind(Vector2.DOWN))
	left.button_down.connect(_set_mobile_direction.bind(Vector2.LEFT))
	right.button_down.connect(_set_mobile_direction.bind(Vector2.RIGHT))
	for button in [up, down, left, right]: button.button_up.connect(_set_mobile_direction.bind(Vector2.ZERO))

	var attack := _touch_button("ATTACK", Vector2(size.x - 184, size.y - 228), Vector2(142, 78))
	var power := _touch_button("POWER", Vector2(size.x - 204, size.y - 137), Vector2(162, 70))
	var boost := _touch_button("BOOST", Vector2(size.x - 355, size.y - 112), Vector2(120, 60))
	root.add_child(attack)
	root.add_child(power)
	root.add_child(boost)
	attack.button_down.connect(_set_mobile_attack.bind(true))
	attack.button_up.connect(_set_mobile_attack.bind(false))
	power.pressed.connect(_activate_ability)
	boost.pressed.connect(_boost)

func _touch_button(text: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _box(Color(0.04, 0.16, 0.19, 0.88), Color("#4cc6a2"), 2, 18))
	button.add_theme_stylebox_override("pressed", _box(Color(0.18, 0.55, 0.44, 0.95), Color("#b4ffcf"), 2, 18))
	return button

func _set_mobile_direction(direction: Vector2) -> void:
	player.set_mobile_vector(direction)

func _set_mobile_attack(active: bool) -> void:
	mobile_attack = active

func _update_hud() -> void:
	if not hud_score:
		return
	hud_score.text = "KILLS  %d" % kills
	hud_timer.text = "%d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	hud_wave.text = "WAVE  %d" % wave
	var power_status := "READY" if ability_clock <= 0.0 else "%.1fs" % ability_clock
	hud_power.text = "%s  •  %s    |    %s  •  %s" % [weapon_data["name"], "SPACE / ATTACK", ability_data["name"], power_status]

func _spawn_slash(direction: Vector2) -> void:
	var line := Line2D.new()
	line.width = 12.0
	line.default_color = Color("#fff2b3")
	line.points = PackedVector2Array([player.global_position + direction.rotated(-0.65) * 62.0, player.global_position + direction * 95.0, player.global_position + direction.rotated(0.65) * 62.0])
	add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(line.queue_free)

func _spawn_flame(direction: Vector2) -> void:
	for i in range(5):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([Vector2(-8, 8), Vector2(0, -14), Vector2(8, 8)])
		spark.color = Color("#ff8b42") if i % 2 == 0 else Color("#ffd55c")
		spark.global_position = player.global_position + direction.rotated(randf_range(-0.35, 0.35)) * randf_range(50, 150)
		add_child(spark)
		var tween := create_tween()
		tween.tween_property(spark, "scale", Vector2(2.4, 2.4), 0.2)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.2)
		tween.tween_callback(spark.queue_free)

func _spawn_ring(position: Vector2, color: Color, radius: float) -> void:
	var ring := Line2D.new()
	ring.width = 7.0
	ring.default_color = color
	var points := PackedVector2Array()
	for i in range(33): points.append(Vector2.RIGHT.rotated(i * TAU / 32.0) * 16.0)
	ring.points = points
	ring.closed = true
	ring.global_position = position
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * (radius / 16.0), 0.35)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)

func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box
