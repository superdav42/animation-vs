extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal defeated

var target: Node2D
var weapon_id := ""
var vehicle_id := ""
var ability_id := ""
var weapon_data: Dictionary
var vehicle_data: Dictionary
var ability_data: Dictionary
var base_speed := 300.0
var max_health := 100.0
var health := 100.0
var facing := Vector2.DOWN
var invulnerable_time := 0.0
var slow_time := 0.0
var slow_multiplier := 1.0
var strafe_direction := 1.0
var body_color := Color("#f08bb1")
var skin_shape := "square"
var design := "visor"
var walk_phase := 0.0
var human_controlled := false
var mobile_vector := Vector2.ZERO
var can_fly := false
var vehicle_can_fly := false
var boost_time := 0.0
var boost_cooldown := 0.0
var boost_multiplier := 1.3
var ground_level := 1035.0
var jump_requested := false
var jump_speed := 690.0
var inverted_gravity := false

const GRAVITY := 1900.0
const FLIGHT_THRUST := 1550.0
const CEILING_Y := 285.0

func configure(loadout: Dictionary, chase_target: Node2D, player_color := Color("#63e6bc"), player_design := "classic", player_shape := "round") -> void:
	target = chase_target
	weapon_id = loadout["weapons"]
	vehicle_id = loadout["vehicles"]
	ability_id = loadout["abilities"]
	weapon_data = loadout["weapon_data"]
	vehicle_data = loadout["vehicle_data"]
	ability_data = loadout["ability_data"]
	vehicle_can_fly = bool(vehicle_data.get("flight", false))
	can_fly = ability_data.get("style", "") == "flight" or vehicle_can_fly
	var color_options := [Color("#f08bb1"), Color("#ff765f"), Color("#bf82ff"), Color("#f0c45b")]
	color_options = color_options.filter(func(color: Color) -> bool: return not color.is_equal_approx(player_color))
	body_color = color_options.pick_random()
	var shape_options := ["round", "cap", "hood", "square", "orbit"]
	shape_options.erase(player_shape)
	skin_shape = shape_options.pick_random()
	var design_options := ["classic", "visor", "bolt"]
	design_options.erase(player_design)
	design = design_options.pick_random()
	base_speed = float(vehicle_data.get("speed", 300.0))
	boost_multiplier = float(vehicle_data.get("boost", 1.3))
	max_health = 100.0 + float(vehicle_data.get("armor", 0))
	health = max_health
	ground_level = 245.0 if inverted_gravity else get_viewport_rect().size.y - 245.0
	rotation = PI if inverted_gravity else 0.0
	health_changed.emit(health, max_health)
	queue_redraw()

func _ready() -> void:
	add_to_group("cpu")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	collision.shape = shape
	add_child(collision)
	strafe_direction = -1.0 if randf() < 0.5 else 1.0

func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	boost_time = maxf(0.0, boost_time - delta)
	boost_cooldown = maxf(0.0, boost_cooldown - delta)
	if not is_instance_valid(target) or health <= 0.0:
		velocity.x = 0.0
		velocity.y += GRAVITY * _gravity_direction() * delta
		move_and_slide()
		return
	var to_target := global_position.direction_to(target.global_position)
	var movement := Vector2.ZERO
	if human_controlled:
		movement = mobile_vector
	else:
		var horizontal_distance := absf(target.global_position.x - global_position.x)
		var desired_range := _desired_range()
		if horizontal_distance > desired_range + 55.0:
			movement.x = signf(target.global_position.x - global_position.x)
		elif horizontal_distance < desired_range - 35.0:
			movement.x = -signf(target.global_position.x - global_position.x)
		if can_fly and target.global_position.y < global_position.y - 70.0:
			movement.y = -1.0
	var horizontal := clampf(movement.x, -1.0, 1.0)
	var gravity_direction := _gravity_direction()
	var wants_flight := movement.y * gravity_direction < -0.45
	var grounded := global_position.y <= ground_level + 1.0 if inverted_gravity else global_position.y >= ground_level - 1.0
	if absf(to_target.x) > 0.01:
		facing = Vector2(signf(to_target.x), 0.0)
	if human_controlled and absf(horizontal) > 0.05:
		facing = Vector2(signf(horizontal), 0.0)
	var speed := base_speed * (boost_multiplier if boost_time > 0.0 else 1.0)
	if slow_time > 0.0:
		speed *= slow_multiplier
	velocity.x = horizontal * speed
	if grounded and jump_requested:
		velocity.y = -jump_speed * gravity_direction
	elif can_fly and wants_flight and _has_flight_room():
		velocity.y = move_toward(velocity.y, -520.0 * gravity_direction, FLIGHT_THRUST * delta)
	else:
		velocity.y += GRAVITY * gravity_direction * delta
	if can_fly and movement.y * gravity_direction > 0.45:
		velocity.y += FLIGHT_THRUST * gravity_direction * delta
	jump_requested = false
	move_and_slide()
	walk_phase += absf(velocity.x) * delta * 0.035
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 48.0, size.x - 48.0)
	if inverted_gravity:
		global_position.y = clampf(global_position.y, ground_level, size.y - CEILING_Y)
	else:
		global_position.y = clampf(global_position.y, CEILING_Y, ground_level)
	if (inverted_gravity and global_position.y <= ground_level) or (not inverted_gravity and global_position.y >= ground_level):
		velocity.y = 0.0
	queue_redraw()

func _gravity_direction() -> float:
	return -1.0 if inverted_gravity else 1.0

func _has_flight_room() -> bool:
	return global_position.y < get_viewport_rect().size.y - CEILING_Y if inverted_gravity else global_position.y > CEILING_Y

func _desired_range() -> float:
	match weapon_data.get("style", "projectile"):
		"melee": return 82.0
		"flame": return 175.0
	return 330.0

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	var minimum_y := ground_level if inverted_gravity else CEILING_Y
	var maximum_y := size.y - CEILING_Y if inverted_gravity else ground_level
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, minimum_y, maximum_y))
	velocity.y = 0.0
	invulnerable_time = 0.5

func set_mobile_vector(value: Vector2) -> void:
	mobile_vector = value

func request_jump() -> void:
	jump_requested = true

func try_boost() -> bool:
	if vehicle_id.is_empty() or boost_cooldown > 0.0:
		return false
	boost_time = 0.55
	boost_cooldown = 3.0
	return true

func take_damage(amount: float) -> void:
	if invulnerable_time > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerable_time = 0.18
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0.0:
		defeated.emit()

func slow(duration: float, multiplier: float) -> void:
	slow_time = maxf(slow_time, duration)
	slow_multiplier = multiplier

func _draw() -> void:
	var vehicle_color := Color("#d85d91")
	draw_line(Vector2(-31, 46), Vector2(31, 46), Color(0.02, 0.02, 0.055, 0.5), 12.0, true)
	if absf(velocity.x) > 405.0:
		var trail_side := -signf(velocity.x)
		for i in range(3):
			draw_line(Vector2(trail_side * (36 + i * 12), 5 + i * 12), Vector2(trail_side * (70 + i * 16), 5 + i * 12), Color(vehicle_color, 0.42 - i * 0.1), 5.0 - i)
	if not vehicle_id.is_empty():
		match vehicle_id:
			"board", "roller":
				draw_line(Vector2(-26, 23), Vector2(26, 23), vehicle_color, 13.0, true)
				for x in [-16.0, 0.0, 16.0]: draw_line(Vector2(x - 5, 18), Vector2(x + 5, 28), Color("#ffd1e3"), 3.0)
				draw_circle(Vector2(-20, 30), 6.0, Color("#191022"))
				draw_circle(Vector2(20, 30), 6.0, Color("#191022"))
			"spring_cart":
				draw_rect(Rect2(-30, 8, 60, 30), vehicle_color, true)
				for x in [-18.0, 18.0]: draw_polyline(PackedVector2Array([Vector2(x - 6, 38), Vector2(x + 5, 45), Vector2(x - 5, 52)]), Color("#f8b4d1"), 4.0)
			"bike", "hoverbike":
				draw_circle(Vector2(-24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_circle(Vector2(24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_line(Vector2(-20, 22), Vector2(24, 8), vehicle_color, 7.0, true)
				for x in range(-12, 22, 10): draw_line(Vector2(x, 17), Vector2(x + 7, 10), Color("#ffc0dc"), 2.0)
			"tread_cycle":
				draw_rect(Rect2(-34, 8, 68, 30), vehicle_color, true)
				draw_arc(Vector2.ZERO + Vector2(0, 34), 31.0, 0.1, PI - 0.1, 16, Color("#26162e"), 8.0)
			"buggy", "mech":
				draw_colored_polygon(PackedVector2Array([Vector2(-38, 36), Vector2(-30, 2), Vector2(16, -3), Vector2(37, 15), Vector2(34, 38)]), vehicle_color)
				draw_polyline(PackedVector2Array([Vector2(-38, 36), Vector2(-30, 2), Vector2(16, -3), Vector2(37, 15)]), Color("#ffd0eb"), 4.0)
				for x in range(-26, 25, 13): draw_line(Vector2(x, 7), Vector2(x + 10, 38), Color("#ffcf55"), 3.0)
				for wheel_x in [-25.0, 25.0]:
					draw_circle(Vector2(wheel_x, 40), 11.0, Color("#271329"))
					draw_circle(Vector2(wheel_x, 40), 5.0, Color("#ff91d1"), false, 3.0)
			"crab_tank":
				draw_colored_polygon(PackedVector2Array([Vector2(-38, 34), Vector2(-27, 3), Vector2(27, 3), Vector2(38, 34)]), vehicle_color)
				for x in [-28.0, -10.0, 10.0, 28.0]: draw_line(Vector2(x, 30), Vector2(x + signf(x) * 12, 48), Color("#5d284f"), 7.0)
			"saucer":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(34, 24), Vector2(0, 38), Vector2(-34, 24)]), vehicle_color)
				for x in [-20.0, 0.0, 20.0]: draw_circle(Vector2(x, 21), 4.0, Color("#fff08d"))
			"rocket", "meteor_pod":
				var flame_length := 22.0 + absf(sin(Time.get_ticks_msec() * 0.018)) * 18.0 + (16.0 if boost_time > 0.0 else 0.0)
				for nozzle_x in [-18.0, 18.0]:
					draw_colored_polygon(PackedVector2Array([Vector2(nozzle_x - 8, 29), Vector2(nozzle_x, 38 + flame_length), Vector2(nozzle_x + 8, 29)]), Color("#d447a4"))
					draw_colored_polygon(PackedVector2Array([Vector2(nozzle_x - 4, 30), Vector2(nozzle_x, 32 + flame_length * 0.65), Vector2(nozzle_x + 4, 30)]), Color("#fff27a"))
				draw_colored_polygon(PackedVector2Array([Vector2(-38, 27), Vector2(-28, 0), Vector2(0, -17), Vector2(28, 0), Vector2(38, 27), Vector2(25, 37), Vector2(-25, 37)]), vehicle_color)
				draw_polyline(PackedVector2Array([Vector2(-38, 27), Vector2(-28, 0), Vector2(0, -17), Vector2(28, 0), Vector2(38, 27)]), Color("#ffe0f1"), 4.0)
				draw_circle(Vector2(0, 5), 10.0, Color("#351633"))
				draw_circle(Vector2(0, 5), 6.0, Color("#ff9de0"))
	_draw_ability_texture()
	var stride := sin(walk_phase) * (8.0 if velocity.length_squared() > 10.0 else 1.5)
	var outline := Color("#160e22")
	draw_circle(Vector2(0, -30), 18.0, Color(body_color, 0.13))
	draw_circle(Vector2(0, -30), 15.0, outline, false, 11.0)
	draw_line(Vector2(0, -15), Vector2(0, 19), outline, 13.0, true)
	draw_line(Vector2(0, -7), Vector2(-19 - stride * 0.35, 8), outline, 12.0, true)
	var weapon_hand := Vector2(facing.x * 29.0, -4)
	draw_line(Vector2(0, -7), weapon_hand, outline, 12.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), outline, 13.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), outline, 13.0, true)
	if skin_shape == "orbit":
		draw_circle(Vector2(0, -28), 24.0, Color(body_color, 0.18), false, 5.0)
		draw_circle(Vector2(22, -30 + sin(walk_phase) * 4.0), 5.0, Color("#ff6b93"))
	if skin_shape == "square":
		draw_rect(Rect2(-15, -44, 30, 28), body_color, false, 6.0)
	else:
		draw_circle(Vector2(0, -30), 14.0, body_color, false, 6.0)
	if skin_shape == "cap":
		draw_line(Vector2(-13, -45), Vector2(13, -45), body_color, 6.0, true)
		draw_line(Vector2(8, -44), Vector2(21, -39), body_color, 5.0, true)
	elif skin_shape == "hood":
		draw_polyline(PackedVector2Array([Vector2(-18, -23), Vector2(-16, -48), Vector2(0, -57), Vector2(16, -48), Vector2(18, -23)]), body_color, 5.0, true)
		draw_line(Vector2(12, -22), Vector2(29, -9), body_color, 5.0, true)
	draw_line(Vector2(0, -15), Vector2(0, 19), body_color, 7.0, true)
	draw_line(Vector2(0, -7), Vector2(-19 - stride * 0.35, 8), body_color, 6.0, true)
	draw_line(Vector2(0, -7), weapon_hand, body_color, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), body_color, 7.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), body_color, 7.0, true)
	for joint in [Vector2(0, -7), Vector2(0, 18), weapon_hand]:
		draw_circle(joint, 4.5, Color("#ffecf4"))
	if design == "visor":
		draw_line(Vector2(-10, -31), Vector2(10, -31), Color("#151527"), 5.0, true)
	elif design == "bolt":
		draw_polyline(PackedVector2Array([Vector2(-4, -39), Vector2(3, -32), Vector2(-3, -25), Vector2(5, -20)]), Color("#fff3a3"), 3.0)
	draw_circle(weapon_hand, 4.0, Color("#ffecf4"))
	_draw_weapon(weapon_hand, facing.x)

func _draw_weapon(hand: Vector2, side: float) -> void:
	var tip := hand + Vector2(side * 45.0, -4.0)
	match weapon_id:
		"dagger":
			draw_colored_polygon(PackedVector2Array([hand, tip + Vector2(0, -8), tip + Vector2(side * 17, 0), tip + Vector2(0, 8)]), Color("#e6dce4"))
			draw_polyline(PackedVector2Array([hand, tip + Vector2(0, -8), tip + Vector2(side * 17, 0), tip + Vector2(0, 8), hand]), Color("#ffb5dc"), 3.0)
		"bat":
			draw_line(hand, tip + Vector2(side * 17, -4), Color("#aa6d62"), 16.0, true)
			for i in range(4): draw_line(hand + Vector2(side * (7 + i * 7), -9), hand + Vector2(side * (12 + i * 7), 7), Color("#ffd5e9"), 4.0)
		"bow":
			draw_arc(hand + Vector2(side * 21, 0), 31.0, -PI * 0.5, PI * 0.5, 16, Color("#ff75bb"), 7.0)
			draw_line(hand + Vector2(side * 21, -31), hand + Vector2(side * 21, 31), Color("#fff1fa"), 3.0)
		"flame":
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 44.0), -13), Vector2(44, 26)), Color("#a83a79"), true)
			for i in range(4): draw_line(hand + Vector2(side * (7 + i * 9), -11), hand + Vector2(side * (13 + i * 9), 11), Color("#ff8dcc"), 4.0)
		"wrench", "spear", "star_lance":
			draw_line(hand, tip + Vector2(side * 14, 0), Color("#d19abb"), 12.0, true)
			draw_line(tip + Vector2(side * 6, -10), tip + Vector2(side * 17, 10), Color("#fff0fa"), 7.0)
			for i in range(3): draw_line(hand + Vector2(side * (11 + i * 11), -7), hand + Vector2(side * (17 + i * 11), 7), Color("#642553"), 4.0)
		"shock_hammer":
			draw_line(hand, tip, Color("#8d557e"), 8.0)
			draw_rect(Rect2(tip + Vector2(-10, -14), Vector2(20, 28)), Color("#e06bb0"), true)
			draw_line(tip + Vector2(-7, -8), tip + Vector2(7, 8), Color("#ffe875"), 3.0)
		"plasma":
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 38.0), -10), Vector2(38, 20)), Color("#983f80"), true)
			for i in range(3): draw_line(hand + Vector2(side * (7 + i * 8), -7), hand + Vector2(side * (12 + i * 8), 7), Color("#ff96db"), 2.0)
		_:
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 49.0), -13), Vector2(49, 26)), Color("#813e72"), true)
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 44.0), -9), Vector2(44, 8)), Color("#ff96cf"), true)
			for i in range(3): draw_circle(hand + Vector2(side * (12 + i * 12), 6), 3.5, Color("#8de5ff"))

func _draw_ability_texture() -> void:
	var style: String = ability_data.get("style", "")
	var pulse := 0.65 + sin(Time.get_ticks_msec() * 0.007) * 0.2
	match style:
		"burst":
			for radius in [31.0, 39.0, 47.0]: draw_arc(Vector2(0, -7), radius, -2.7, -0.45, 12, Color(0.4, 0.75, 1.0, pulse * 0.6), 4.0)
		"vine":
			draw_arc(Vector2(0, -5), 39.0, 0.1, PI * 1.6, 18, Color("#e060b2"), 5.0)
			for angle in [0.4, 1.2, 2.1]: draw_circle(Vector2.RIGHT.rotated(angle) * 39.0 + Vector2(0, -5), 5.0, Color("#ff9fd6"))
		"blink":
			for i in range(5): draw_rect(Rect2(-45 + i * 19, -62 + (i % 2) * 12, 9, 9), Color(0.95, 0.35, 0.75, pulse), true)
		"inferno":
			for i in range(8): draw_line(Vector2.RIGHT.rotated(i * TAU / 8.0) * 34.0 + Vector2(0, -7), Vector2.RIGHT.rotated(i * TAU / 8.0) * 50.0 + Vector2(0, -7), Color("#d05cff"), 6.0)
		"flight":
			var wing_alpha := 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.2
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(-48, -36), Vector2(-30, 10)]), Color(0.95, 0.45, 0.82, wing_alpha))
			draw_colored_polygon(PackedVector2Array([Vector2(4, -5), Vector2(48, -36), Vector2(30, 10)]), Color(0.95, 0.45, 0.82, wing_alpha))
