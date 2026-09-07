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
var boost_time := 0.0
var boost_cooldown := 0.0
var boost_multiplier := 1.3
var ground_level := 1035.0

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
	can_fly = ability_data.get("style", "") == "flight"
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
	ground_level = get_viewport_rect().size.y - 245.0
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
		velocity.y += GRAVITY * delta
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
	var wants_jump := movement.y < -0.45
	if absf(to_target.x) > 0.01:
		facing = Vector2(signf(to_target.x), 0.0)
	if human_controlled and absf(horizontal) > 0.05:
		facing = Vector2(signf(horizontal), 0.0)
	var speed := base_speed * (boost_multiplier if boost_time > 0.0 else 1.0)
	if slow_time > 0.0:
		speed *= slow_multiplier
	velocity.x = horizontal * speed
	if can_fly and wants_jump and global_position.y > CEILING_Y:
		velocity.y = move_toward(velocity.y, -520.0, FLIGHT_THRUST * delta)
	else:
		velocity.y += GRAVITY * delta
	if can_fly and movement.y > 0.45:
		velocity.y += FLIGHT_THRUST * delta
	move_and_slide()
	walk_phase += absf(velocity.x) * delta * 0.035
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 48.0, size.x - 48.0)
	global_position.y = clampf(global_position.y, CEILING_Y, ground_level)
	if global_position.y >= ground_level:
		velocity.y = 0.0
	queue_redraw()

func _desired_range() -> float:
	match weapon_data.get("style", "projectile"):
		"melee": return 82.0
		"flame": return 175.0
	return 330.0

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, CEILING_Y, ground_level))
	velocity.y = 0.0
	invulnerable_time = 0.5

func set_mobile_vector(value: Vector2) -> void:
	mobile_vector = value

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
	if not vehicle_id.is_empty():
		match vehicle_id:
			"roller":
				draw_line(Vector2(-26, 23), Vector2(26, 23), vehicle_color, 13.0, true)
				for x in [-16.0, 0.0, 16.0]: draw_line(Vector2(x - 5, 18), Vector2(x + 5, 28), Color("#ffd1e3"), 3.0)
			"spring_cart":
				draw_rect(Rect2(-30, 8, 60, 30), vehicle_color, true)
				for x in [-18.0, 18.0]: draw_polyline(PackedVector2Array([Vector2(x - 6, 38), Vector2(x + 5, 45), Vector2(x - 5, 52)]), Color("#f8b4d1"), 4.0)
			"hoverbike":
				draw_circle(Vector2(-24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_circle(Vector2(24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_line(Vector2(-20, 22), Vector2(24, 8), vehicle_color, 7.0, true)
				for x in range(-12, 22, 10): draw_line(Vector2(x, 17), Vector2(x + 7, 10), Color("#ffc0dc"), 2.0)
			"tread_cycle":
				draw_rect(Rect2(-34, 8, 68, 30), vehicle_color, true)
				draw_arc(Vector2.ZERO + Vector2(0, 34), 31.0, 0.1, PI - 0.1, 16, Color("#26162e"), 8.0)
			"mech":
				draw_rect(Rect2(-33, 4, 66, 38), vehicle_color)
				for x in range(-26, 25, 13): draw_line(Vector2(x, 7), Vector2(x + 10, 38), Color("#ffcf55"), 3.0)
				draw_line(Vector2(-22, 39), Vector2(-29, 52), Color("#40203d"), 9.0)
				draw_line(Vector2(22, 39), Vector2(29, 52), Color("#40203d"), 9.0)
			"crab_tank":
				draw_colored_polygon(PackedVector2Array([Vector2(-38, 34), Vector2(-27, 3), Vector2(27, 3), Vector2(38, 34)]), vehicle_color)
				for x in [-28.0, -10.0, 10.0, 28.0]: draw_line(Vector2(x, 30), Vector2(x + signf(x) * 12, 48), Color("#5d284f"), 7.0)
			"saucer":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(34, 24), Vector2(0, 38), Vector2(-34, 24)]), vehicle_color)
				for x in [-20.0, 0.0, 20.0]: draw_circle(Vector2(x, 21), 4.0, Color("#fff08d"))
			"meteor_pod":
				draw_circle(Vector2(0, 18), 35.0, vehicle_color)
				draw_line(Vector2(-22, 3), Vector2(18, 31), Color("#6e304f"), 4.0)
				draw_line(Vector2(5, -8), Vector2(-8, 42), Color("#ffc071"), 3.0)
	if can_fly:
		var wing_alpha := 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.2
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(-42, -30), Vector2(-28, 8)]), Color(0.95, 0.45, 0.82, wing_alpha))
		draw_colored_polygon(PackedVector2Array([Vector2(4, -5), Vector2(42, -30), Vector2(28, 8)]), Color(0.95, 0.45, 0.82, wing_alpha))
	var stride := sin(walk_phase) * (8.0 if velocity.length_squared() > 10.0 else 1.5)
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
	var weapon_hand := Vector2(facing.x * 29.0, -4)
	draw_line(Vector2(0, -7), weapon_hand, body_color, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), body_color, 7.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), body_color, 7.0, true)
	if design == "visor":
		draw_line(Vector2(-10, -31), Vector2(10, -31), Color("#151527"), 5.0, true)
	elif design == "bolt":
		draw_polyline(PackedVector2Array([Vector2(-4, -39), Vector2(3, -32), Vector2(-3, -25), Vector2(5, -20)]), Color("#fff3a3"), 3.0)
	draw_circle(weapon_hand, 4.0, Color("#ffecf4"))
	_draw_weapon(weapon_hand, facing.x)

func _draw_weapon(hand: Vector2, side: float) -> void:
	var tip := hand + Vector2(side * 36.0, -4.0)
	match weapon_id:
		"wrench", "spear", "star_lance":
			draw_line(hand, tip + Vector2(side * 10, 0), Color("#b987a9"), 8.0, true)
			draw_line(tip + Vector2(side * 5, -7), tip + Vector2(side * 13, 7), Color("#ffd1ed"), 5.0)
			for i in range(2): draw_line(hand + Vector2(side * (12 + i * 10), -4), hand + Vector2(side * (16 + i * 10), 4), Color("#6d315e"), 2.0)
		"shock_hammer":
			draw_line(hand, tip, Color("#8d557e"), 8.0)
			draw_rect(Rect2(tip + Vector2(-10, -14), Vector2(20, 28)), Color("#e06bb0"), true)
			draw_line(tip + Vector2(-7, -8), tip + Vector2(7, 8), Color("#ffe875"), 3.0)
		"plasma":
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 38.0), -10), Vector2(38, 20)), Color("#983f80"), true)
			for i in range(3): draw_line(hand + Vector2(side * (7 + i * 8), -7), hand + Vector2(side * (12 + i * 8), 7), Color("#ff96db"), 2.0)
		_:
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 38.0), -9), Vector2(38, 18)), Color("#813e72"), true)
			draw_line(hand + Vector2(side * 6, -5), hand + Vector2(side * 31, -5), Color("#ff96cf"), 3.0)
			for i in range(2): draw_circle(hand + Vector2(side * (13 + i * 12), 4), 2.5, Color("#8de5ff"))
