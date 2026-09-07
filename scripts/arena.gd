extends Node2D

signal round_finished(summary: Dictionary)

const PlayerScene := preload("res://scenes/player.tscn")
const CpuScript := preload("res://scripts/cpu_fighter.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const VineScript := preload("res://scripts/vine.gd")
const ArenaArtScript := preload("res://scripts/arena_art.gd")
const JoystickScript := preload("res://scripts/virtual_joystick.gd")

const ROUND_LENGTH := 60.0

var player: CharacterBody2D
var cpu: CharacterBody2D
var arena_art: Node2D
var cpu_loadout: Dictionary
var player_health_bar: ProgressBar
var cpu_health_bar: ProgressBar
var hud_player: Label
var hud_cpu: Label
var hud_timer: Label
var hud_power: Label
var hint_label: Label
var time_left := ROUND_LENGTH
var attack_clock := 0.0
var ability_clock := 0.0
var cpu_attack_clock := 1.0
var cpu_ability_clock := 3.0
var mobile_attack := false
var target_stage := 0
var vine_start := Vector2.ZERO
var aim_position := Vector2.ZERO
var finished := false
var weapon_id := "dagger"
var ability_id := ""
var vehicle_id := ""
var weapon_data: Dictionary
var ability_data: Dictionary
var game_mode := "cpu"
var player_two_attack := false
var player_horizontal := 0.0
var player_jump := false
var player_two_horizontal := 0.0
var player_two_jump := false

func _ready() -> void:
	randomize()
	arena_art = ArenaArtScript.new()
	arena_art.configure(Progress.selected_arena)
	arena_art.z_index = -10
	add_child(arena_art)

	weapon_id = Progress.equipped["weapons"]
	ability_id = Progress.equipped["abilities"]
	vehicle_id = Progress.equipped["vehicles"]
	weapon_data = GearCatalog.item("weapons", weapon_id)
	ability_data = GearCatalog.item("abilities", ability_id) if not ability_id.is_empty() else {}
	cpu_loadout = GearCatalog.build_cpu_loadout(Progress.equipped)

	player = PlayerScene.instantiate()
	player.global_position = Vector2(get_viewport_rect().size.x * 0.25, arena_art.ground_y())
	player.keyboard_enabled = not Progress.mobile_mode and game_mode == "cpu"
	player.add_to_group("player")
	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)
	add_child(player)

	cpu = CpuScript.new()
	cpu.global_position = Vector2(get_viewport_rect().size.x * 0.75, arena_art.ground_y())
	cpu.human_controlled = game_mode == "multiplayer"
	cpu.health_changed.connect(_on_cpu_health_changed)
	cpu.defeated.connect(_on_opponent_defeated)
	add_child(cpu)

	_build_hud()
	var player_skin: Dictionary = GearCatalog.item("skins", Progress.equipped["skins"])
	var player_color: Color = GearCatalog.PLAYER_COLORS.get(Progress.player_color, Color("#63e6bc"))
	player.configure(GearCatalog.item("vehicles", vehicle_id) if not vehicle_id.is_empty() else {}, vehicle_id, player_skin, player_color, Progress.player_design, weapon_id, ability_data)
	cpu.configure(cpu_loadout, player, player_color, Progress.player_design, player_skin.get("shape", "round"))
	player.facing = Vector2.RIGHT
	cpu.facing = Vector2.LEFT
	aim_position = cpu.global_position
	player.set_aim(aim_position)
	hint_label.text = _cpu_intro_text()
	var tween := create_tween()
	tween.tween_interval(2.8)
	tween.tween_callback(_clear_intro_hint)
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	time_left = maxf(0.0, time_left - delta)
	attack_clock = maxf(0.0, attack_clock - delta)
	ability_clock = maxf(0.0, ability_clock - delta)
	cpu_attack_clock = maxf(0.0, cpu_attack_clock - delta)
	cpu_ability_clock = maxf(0.0, cpu_ability_clock - delta)
	if (mobile_attack or (not Progress.mobile_mode and Input.is_action_pressed("attack"))) and target_stage == 0:
		_player_attack()
	if not Progress.mobile_mode and Input.is_action_just_pressed("ability"):
		_activate_player_ability()
	if not Progress.mobile_mode and Input.is_action_just_pressed("boost"):
		_player_boost()
	if game_mode == "multiplayer":
		if player_two_attack and target_stage == 0:
			_cpu_attack()
	else:
		_cpu_think()
	_check_projectile_hits()
	_update_hud()
	if time_left <= 0.0:
		_finish_timeout()

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
		_finish_round(false, "FORFEIT")

func _handle_world_tap(point: Vector2) -> void:
	if target_stage == 1:
		vine_start = arena_art.snap_vine_start(point)
		target_stage = 2
		hint_label.text = "VINE READY  •  TAP ITS DESTINATION"
	elif target_stage == 2:
		_create_vine(vine_start, point, "player")
		target_stage = 0
		ability_clock = float(ability_data.get("cooldown", 7.0))
		hint_label.text = ""
	elif target_stage == 3:
		_spawn_ring(player.global_position, Color("#8e85ff"), 70.0)
		player.teleport_to(point)
		_spawn_ring(player.global_position, Color("#8e85ff"), 70.0)
		target_stage = 0
		ability_clock = float(ability_data.get("cooldown", 4.0))
		hint_label.text = ""

func _player_attack() -> void:
	if attack_clock > 0.0 or not is_instance_valid(cpu):
		return
	attack_clock = float(weapon_data.get("cooldown", 0.45))
	var direction: Vector2 = player.facing
	match weapon_data.get("style", "projectile"):
		"melee":
			var to_cpu := player.global_position.direction_to(cpu.global_position)
			if player.global_position.distance_to(cpu.global_position) <= float(weapon_data["range"]) and direction.dot(to_cpu) > 0.1:
				cpu.take_damage(float(weapon_data["damage"]))
			_spawn_slash(player.global_position, direction, Color("#fff2b3"))
		"flame":
			var to_cpu := player.global_position.direction_to(cpu.global_position)
			if player.global_position.distance_to(cpu.global_position) <= float(weapon_data["range"]) and direction.dot(to_cpu) > 0.5:
				cpu.take_damage(float(weapon_data["damage"]))
			_spawn_flame(player.global_position, direction, false)
		_:
			_spawn_projectile(player.global_position, direction, weapon_data, weapon_id, "player")

func _activate_player_ability() -> void:
	if ability_id.is_empty() or ability_clock > 0.0 or target_stage > 0:
		return
	match ability_data.get("style", ""):
		"flight":
			hint_label.text = "GRAVITY WINGS  •  HOLD JUMP TO FLY"
		"burst":
			if player.global_position.distance_to(cpu.global_position) <= 190.0:
				cpu.take_damage(45.0)
			_spawn_ring(player.global_position, Color("#ff784b"), 190.0)
			ability_clock = float(ability_data["cooldown"])
		"vine":
			target_stage = 1
			hint_label.text = "VINE WEAVER  •  TAP GROUND OR A BRANCH"
		"blink":
			target_stage = 3
			hint_label.text = "PHASE BLINK  •  TAP YOUR DESTINATION"
		"inferno":
			cpu.take_damage(80.0)
			_spawn_ring(player.global_position, Color("#ffbc45"), 720.0)
			ability_clock = float(ability_data["cooldown"])

func _player_boost() -> void:
	if player.try_boost():
		_spawn_ring(player.global_position, Color("#4fe2cc"), 90.0)

func _cpu_think() -> void:
	if not is_instance_valid(cpu) or cpu.health <= 0.0:
		return
	var distance := cpu.global_position.distance_to(player.global_position)
	var style: String = cpu.weapon_data.get("style", "projectile")
	var attack_range: float = float(cpu.weapon_data.get("range", 600.0))
	if cpu_attack_clock <= 0.0 and (style == "projectile" or distance <= attack_range + 15.0):
		_cpu_attack()
	if not cpu.ability_id.is_empty() and cpu_ability_clock <= 0.0:
		_cpu_use_ability()

func _cpu_attack() -> void:
	cpu_attack_clock = float(cpu.weapon_data.get("cooldown", 0.6)) * randf_range(1.05, 1.3)
	var direction := cpu.global_position.direction_to(player.global_position)
	match cpu.weapon_data.get("style", "projectile"):
		"melee":
			if cpu.global_position.distance_to(player.global_position) <= float(cpu.weapon_data["range"]) + 12.0:
				player.take_damage(float(cpu.weapon_data["damage"]))
			_spawn_slash(cpu.global_position, direction, Color("#ff78ad"))
		"flame":
			if cpu.global_position.distance_to(player.global_position) <= float(cpu.weapon_data["range"]):
				player.take_damage(float(cpu.weapon_data["damage"]) * 0.72)
			_spawn_flame(cpu.global_position, direction, true)
		_:
			_spawn_projectile(cpu.global_position, direction, cpu.weapon_data, cpu.weapon_id, "cpu")

func _cpu_use_ability() -> void:
	var style: String = cpu.ability_data.get("style", "")
	match style:
		"flight":
			return
		"burst":
			if cpu.global_position.distance_to(player.global_position) > 230.0:
				return
			player.take_damage(28.0)
			_spawn_ring(cpu.global_position, Color("#83d9ff"), 210.0)
		"vine":
			var start: Vector2 = arena_art.snap_vine_start(cpu.global_position)
			var destination: Vector2 = player.global_position + player.velocity * 0.32
			_create_vine(start, destination, "cpu")
		"blink":
			var flank := player.global_position + Vector2(-player.facing.x * 145.0, -120.0)
			_spawn_ring(cpu.global_position, Color("#e66fd0"), 65.0)
			cpu.teleport_to(flank)
			_spawn_ring(cpu.global_position, Color("#e66fd0"), 65.0)
		"inferno":
			player.take_damage(42.0)
			_spawn_ring(cpu.global_position, Color("#d05cff"), 720.0)
	cpu_ability_clock = float(cpu.ability_data.get("cooldown", 7.0)) * randf_range(1.0, 1.25)

func _spawn_projectile(origin: Vector2, direction: Vector2, data: Dictionary, item_id: String, team: String) -> void:
	var projectile := ProjectileScript.new()
	projectile.global_position = origin + direction * 38.0
	projectile.setup(direction, data, item_id, team)
	add_child(projectile)

func _create_vine(from: Vector2, to: Vector2, team: String) -> void:
	var vine := VineScript.new()
	vine.setup(from, to, 58.0 if team == "player" else 34.0, team)
	add_child(vine)

func _check_projectile_hits() -> void:
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
			continue
		var target: Node2D = cpu if projectile.team == "player" else player
		if is_instance_valid(target) and projectile.global_position.distance_to(target.global_position) < 38.0:
			projectile.hit(target)

func _on_player_health_changed(current: float, maximum: float) -> void:
	if player_health_bar:
		player_health_bar.max_value = maximum
		player_health_bar.value = current

func _on_cpu_health_changed(current: float, maximum: float) -> void:
	if cpu_health_bar:
		cpu_health_bar.max_value = maximum
		cpu_health_bar.value = current

func _finish_timeout() -> void:
	var player_ratio: float = player.health / player.max_health
	var cpu_ratio: float = cpu.health / cpu.max_health
	if is_equal_approx(player_ratio, cpu_ratio):
		_finish_round(false, "DRAW")
	else:
		var player_won := player_ratio > cpu_ratio
		var result := ("PLAYER 1 WINS" if player_won else "PLAYER 2 WINS") if game_mode == "multiplayer" else ("VICTORY" if player_won else "DEFEAT")
		_finish_round(player_won, result)

func _on_player_defeated() -> void:
	_finish_round(false, "PLAYER 2 WINS" if game_mode == "multiplayer" else "DEFEAT")

func _on_opponent_defeated() -> void:
	_finish_round(true, "PLAYER 1 WINS" if game_mode == "multiplayer" else "VICTORY")

func _finish_round(won: bool, result: String) -> void:
	if finished:
		return
	finished = true
	var damage_dealt := int(cpu.max_health - cpu.health)
	var score := damage_dealt * 10 + (1000 if won else 0) + int(ROUND_LENGTH - time_left) * 5
	var reward := 110 + int(float(damage_dealt) * 0.35) if won else 30 + int(float(damage_dealt) * 0.15)
	round_finished.emit({
		"won": won,
		"result": result,
		"score": score,
		"credits": reward,
		"damage": damage_dealt,
		"cpu_loadout": cpu_loadout,
		"opponent_label": "PLAYER 2" if game_mode == "multiplayer" else "CPU",
		"game_mode": game_mode,
	})

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(22, 490 if game_mode == "multiplayer" else 20)
	top_panel.size = Vector2(get_viewport_rect().size.x - 44, 92)
	top_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.08, 0.11, 0.95), Color("#654c76"), 2, 22))
	root.add_child(top_panel)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top_panel.add_child(top)
	hud_player = _hud_heading("PLAYER 1" if game_mode == "multiplayer" else "YOU", HORIZONTAL_ALIGNMENT_LEFT, Color("#6ee8bd"))
	hud_timer = _hud_heading("1:00", HORIZONTAL_ALIGNMENT_CENTER, Color("#f3edcf"))
	hud_cpu = _hud_heading("PLAYER 2" if game_mode == "multiplayer" else "CPU", HORIZONTAL_ALIGNMENT_RIGHT, Color("#f07eac"))
	top.add_child(hud_player)
	top.add_child(hud_timer)
	top.add_child(hud_cpu)

	var health_y := 587.0 if game_mode == "multiplayer" else 117.0
	player_health_bar = _health_bar(Vector2(30, health_y), Vector2(306, 18), Color("#5ce39e"))
	cpu_health_bar = _health_bar(Vector2(get_viewport_rect().size.x - 336, health_y), Vector2(306, 18), Color("#e969a0"))
	root.add_child(player_health_bar)
	root.add_child(cpu_health_bar)

	hud_power = Label.new()
	hud_power.position = Vector2(28, 613 if game_mode == "multiplayer" else 143)
	hud_power.size = Vector2(get_viewport_rect().size.x - 56, 56)
	hud_power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_power.add_theme_font_size_override("font_size", 16)
	hud_power.add_theme_color_override("font_color", Color("#b8ccc8"))
	root.add_child(hud_power)

	hint_label = Label.new()
	hint_label.position = Vector2(30, 670 if game_mode == "multiplayer" else 202)
	hint_label.size = Vector2(get_viewport_rect().size.x - 60, 78)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color("#ffe08a"))
	root.add_child(hint_label)

	var exit := Button.new()
	exit.text = "×"
	exit.position = Vector2(get_viewport_rect().size.x - 68, 620 if game_mode == "multiplayer" else 154)
	exit.size = Vector2(38, 38)
	exit.add_theme_font_size_override("font_size", 22)
	exit.pressed.connect(_finish_round.bind(false, "FORFEIT"))
	root.add_child(exit)
	if Progress.mobile_mode or game_mode == "multiplayer":
		_build_touch_controls(root)

func _build_touch_controls(root: Control) -> void:
	_build_control_set(root, 1, ability_id, vehicle_id, ability_data.get("style", ""))
	if game_mode == "multiplayer":
		var top_controls := Control.new()
		top_controls.position = get_viewport_rect().size
		top_controls.rotation = PI
		root.add_child(top_controls)
		_build_control_set(top_controls, 2, cpu.ability_id, cpu.vehicle_id, cpu.ability_data.get("style", ""))

func _build_control_set(host: Control, player_number: int, equipped_ability: String, equipped_vehicle: String, ability_style: String) -> void:
	var size := get_viewport_rect().size
	var joystick := JoystickScript.new()
	joystick.position = Vector2(0, size.y - 205)
	joystick.size = Vector2(380, 205)
	joystick.changed.connect(_set_joystick_vector.bind(player_number))
	host.add_child(joystick)
	var move_hint := Label.new()
	move_hint.text = "TOUCH + DRAG TO MOVE / FLY"
	move_hint.position = Vector2(24, size.y - 62)
	move_hint.size = Vector2(340, 38)
	move_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_hint.add_theme_font_size_override("font_size", 15)
	move_hint.add_theme_color_override("font_color", Color(0.72, 0.86, 0.82, 0.72))
	host.add_child(move_hint)
	var boost := _touch_button("BOOST" if not equipped_vehicle.is_empty() else "ON FOOT", Vector2(382, size.y - 112), Vector2(100, 94))
	var power_text := "FLY\nUSE STICK" if ability_style == "flight" else ("POWER" if not equipped_ability.is_empty() else "NO POWER")
	var power := _touch_button(power_text, Vector2(490, size.y - 122), Vector2(100, 104))
	var attack := _touch_button("ATTACK", Vector2(598, size.y - 142), Vector2(112, 124))
	for button in [boost, power, attack]: host.add_child(button)
	attack.button_down.connect(_set_fighter_attack.bind(player_number, true))
	attack.button_up.connect(_set_fighter_attack.bind(player_number, false))
	power.disabled = equipped_ability.is_empty() or ability_style == "flight"
	boost.disabled = equipped_vehicle.is_empty()
	if player_number == 1:
		power.pressed.connect(_activate_player_ability)
		boost.pressed.connect(_player_boost)
	else:
		power.pressed.connect(_cpu_use_ability)
		boost.pressed.connect(_player_two_boost)

func _touch_button(text: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", _box(Color(0.04, 0.16, 0.19, 0.88), Color("#4cc6a2"), 2, 18))
	button.add_theme_stylebox_override("pressed", _box(Color(0.18, 0.55, 0.44, 0.95), Color("#b4ffcf"), 2, 18))
	return button

func _set_mobile_direction(direction: Vector2) -> void:
	player.set_mobile_vector(direction)

func _set_mobile_attack(active: bool) -> void:
	mobile_attack = active

func _set_joystick_vector(value: Vector2, player_number: int) -> void:
	if player_number == 1:
		player.set_mobile_vector(value)
	else:
		cpu.set_mobile_vector(value)

func _set_touch_direction(player_number: int, horizontal: float, jump_control: bool, pressed: bool) -> void:
	if player_number == 1:
		if jump_control:
			player_jump = pressed
		elif pressed or is_equal_approx(player_horizontal, horizontal):
			player_horizontal = horizontal if pressed else 0.0
		player.set_mobile_vector(Vector2(player_horizontal, -1.0 if player_jump else 0.0))
	else:
		if jump_control:
			player_two_jump = pressed
		elif pressed or is_equal_approx(player_two_horizontal, horizontal):
			player_two_horizontal = horizontal if pressed else 0.0
		cpu.set_mobile_vector(Vector2(player_two_horizontal, -1.0 if player_two_jump else 0.0))

func _set_fighter_attack(player_number: int, active: bool) -> void:
	if player_number == 1:
		mobile_attack = active
	else:
		player_two_attack = active

func _player_two_boost() -> void:
	if cpu.try_boost():
		_spawn_ring(cpu.global_position, Color("#e969a0"), 90.0)

func _update_hud() -> void:
	if not hud_timer:
		return
	hud_timer.text = "%d:%02d" % [int(int(time_left) / 60.0), int(time_left) % 60]
	hud_player.text = "%s\n%s" % ["PLAYER 1" if game_mode == "multiplayer" else "YOU", weapon_data["name"]]
	hud_cpu.text = "%s\n%s" % ["PLAYER 2" if game_mode == "multiplayer" else "CPU", cpu.weapon_data["name"]]
	var ability_name: String = ability_data.get("name", "NO ABILITY")
	var ability_status: String = "—" if ability_id.is_empty() else ("HOLD UP" if ability_data.get("style", "") == "flight" else ("READY" if ability_clock <= 0.0 else "%.1fs" % ability_clock))
	hud_power.text = "%s  •  ATTACK     |     %s  •  %s" % [weapon_data["name"], ability_name, ability_status]

func _cpu_intro_text() -> String:
	var opponent := "PLAYER 2" if game_mode == "multiplayer" else "CPU"
	var parts: Array[String] = ["%s DRAW: %s" % [opponent, cpu_loadout["weapon_data"]["name"]]]
	if not cpu_loadout["vehicles"].is_empty(): parts.append(cpu_loadout["vehicle_data"]["name"])
	if not cpu_loadout["abilities"].is_empty(): parts.append(cpu_loadout["ability_data"]["name"])
	return "  •  ".join(parts)

func _clear_intro_hint() -> void:
	if target_stage == 0 and is_instance_valid(hint_label):
		hint_label.text = ""

func _hud_heading(text: String, alignment: HorizontalAlignment, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	return label

func _health_bar(position: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = position
	bar.size = size
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _box(Color("#15232d"), Color.TRANSPARENT, 0, 8))
	bar.add_theme_stylebox_override("fill", _box(color, Color.TRANSPARENT, 0, 8))
	return bar

func _spawn_slash(origin: Vector2, direction: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 12.0
	line.default_color = color
	line.points = PackedVector2Array([origin + direction.rotated(-0.65) * 62.0, origin + direction * 95.0, origin + direction.rotated(0.65) * 62.0])
	add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(line.queue_free)

func _spawn_flame(origin: Vector2, direction: Vector2, cpu_flame: bool) -> void:
	for i in range(5):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([Vector2(-8, 8), Vector2(0, -14), Vector2(8, 8)])
		spark.color = Color("#db5eb4") if cpu_flame else (Color("#ff8b42") if i % 2 == 0 else Color("#ffd55c"))
		spark.global_position = origin + direction.rotated(randf_range(-0.35, 0.35)) * randf_range(50, 150)
		add_child(spark)
		var tween := create_tween()
		tween.tween_property(spark, "scale", Vector2(2.4, 2.4), 0.2)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.2)
		tween.tween_callback(spark.queue_free)

func _spawn_ring(position: Vector2, color: Color, radius: float) -> void:
	for band in range(3):
		var ring := Line2D.new()
		ring.width = 8.0 - band * 2.0
		ring.default_color = Color(color, 0.92 - band * 0.2)
		var points := PackedVector2Array()
		for i in range(33): points.append(Vector2.RIGHT.rotated(i * TAU / 32.0) * (13.0 + band * 5.0))
		ring.points = points
		ring.closed = true
		ring.global_position = position
		ring.rotation = band * 0.18
		add_child(ring)
		var tween := create_tween()
		tween.tween_property(ring, "scale", Vector2.ONE * (radius / (13.0 + band * 5.0)), 0.32 + band * 0.04)
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
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box
