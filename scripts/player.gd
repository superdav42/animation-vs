extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal defeated

var base_speed := 360.0
var boost_multiplier := 1.35
var max_health := 100.0
var health := 100.0
var vehicle_id := "board"
var mobile_vector := Vector2.ZERO
var keyboard_enabled := true
var facing := Vector2.UP
var boost_time := 0.0
var boost_cooldown := 0.0
var invulnerable_time := 0.0
var slow_time := 0.0
var slow_multiplier := 1.0
var body_color := Color("#63e6bc")
var skin_shape := "round"
var design := "classic"
var walk_phase := 0.0
var weapon_id := "dagger"
var ability_style := ""
var can_fly := false
var vehicle_can_fly := false
var ground_level := 1035.0
var jump_requested := false
var jump_speed := 690.0

const GRAVITY := 1900.0
const FLIGHT_THRUST := 1550.0
const CEILING_Y := 285.0

func configure(data: Dictionary, equipped_vehicle: String, skin_data := {}, fighter_color := Color("#63e6bc"), fighter_design := "classic", equipped_weapon := "dagger", equipped_ability := {}) -> void:
	vehicle_id = equipped_vehicle
	weapon_id = equipped_weapon
	ability_style = equipped_ability.get("style", "")
	vehicle_can_fly = bool(data.get("flight", false))
	can_fly = ability_style == "flight" or vehicle_can_fly
	body_color = fighter_color
	skin_shape = skin_data.get("shape", "round")
	design = fighter_design
	base_speed = float(data.get("speed", 360.0))
	boost_multiplier = float(data.get("boost", 1.35))
	max_health = 100.0 + float(data.get("armor", 0))
	health = max_health
	health_changed.emit(health, max_health)
	ground_level = get_viewport_rect().size.y - 245.0
	queue_redraw()

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 27.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _physics_process(delta: float) -> void:
	boost_time = maxf(0.0, boost_time - delta)
	boost_cooldown = maxf(0.0, boost_cooldown - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down") if keyboard_enabled else Vector2.ZERO
	var movement := mobile_vector if mobile_vector.length_squared() > keyboard.length_squared() else keyboard
	var horizontal := clampf(movement.x, -1.0, 1.0)
	var wants_flight := movement.y < -0.45
	var grounded := global_position.y >= ground_level - 1.0
	var keyboard_jump := keyboard_enabled and Input.is_action_just_pressed("move_up")
	if absf(horizontal) > 0.05:
		facing = Vector2(signf(horizontal), 0.0)
	var speed := base_speed * (boost_multiplier if boost_time > 0.0 else 1.0)
	if slow_time > 0.0:
		speed *= slow_multiplier
	velocity.x = horizontal * speed
	if grounded and (jump_requested or keyboard_jump):
		velocity.y = -jump_speed
	elif can_fly and wants_flight and global_position.y > CEILING_Y:
		velocity.y = move_toward(velocity.y, -520.0, FLIGHT_THRUST * delta)
	else:
		velocity.y += GRAVITY * delta
	if can_fly and movement.y > 0.45:
		velocity.y += FLIGHT_THRUST * delta
	jump_requested = false
	move_and_slide()
	walk_phase += absf(velocity.x) * delta * 0.035
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 48.0, size.x - 48.0)
	global_position.y = clampf(global_position.y, CEILING_Y, ground_level)
	if global_position.y >= ground_level:
		velocity.y = 0.0
	queue_redraw()

func set_mobile_vector(value: Vector2) -> void:
	mobile_vector = value

func request_jump() -> void:
	jump_requested = true

func set_aim(point: Vector2) -> void:
	var direction := global_position.direction_to(point)
	if absf(direction.x) > 0.01:
		facing = Vector2(signf(direction.x), 0.0)

func try_boost() -> bool:
	if vehicle_id.is_empty() or boost_cooldown > 0.0:
		return false
	boost_time = 0.55
	boost_cooldown = 3.0
	return true

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, CEILING_Y, ground_level))
	velocity.y = 0.0
	invulnerable_time = 0.7

func slow(duration: float, multiplier: float) -> void:
	slow_time = maxf(slow_time, duration)
	slow_multiplier = multiplier

func take_damage(amount: float) -> void:
	if invulnerable_time > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerable_time = 0.35
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0.0:
		defeated.emit()

func _draw() -> void:
	var pulse := 0.55 if invulnerable_time > 0.0 else 1.0
	var vehicle_color := Color("#43d9bd")
	match vehicle_id:
		"bike": vehicle_color = Color("#65da88")
		"buggy": vehicle_color = Color("#5ca4ff")
		"rocket": vehicle_color = Color("#ffad47")
	var direction := facing
	var stride := sin(walk_phase) * (8.0 if velocity.length_squared() > 10.0 else 1.5)
	draw_line(Vector2(-31, 46), Vector2(31, 46), Color(0.01, 0.035, 0.05, 0.48), 12.0, true)
	if absf(velocity.x) > 405.0:
		var trail_side := -signf(velocity.x)
		for i in range(3):
			draw_line(Vector2(trail_side * (36 + i * 12), 5 + i * 12), Vector2(trail_side * (70 + i * 16), 5 + i * 12), Color(vehicle_color, 0.42 - i * 0.1), 5.0 - i)
	match vehicle_id:
		"board":
			draw_line(Vector2(-25, 23), Vector2(25, 23), vehicle_color, 12.0, true)
			for x in [-16.0, 0.0, 16.0]: draw_circle(Vector2(x, 22), 2.2, Color("#e9c878"))
			draw_circle(Vector2(-20, 29), 6.0, Color("#08131d"))
			draw_circle(Vector2(20, 29), 6.0, Color("#08131d"))
		"bike":
			draw_circle(Vector2(-23, 24), 13.0, Color("#102632"), false, 4.0)
			draw_circle(Vector2(23, 24), 13.0, Color("#102632"), false, 4.0)
			draw_line(Vector2(-22, 24), Vector2(7, 4), vehicle_color, 6.0, true)
			draw_line(Vector2(7, 4), Vector2(23, 24), vehicle_color, 6.0, true)
			draw_line(Vector2(-8, 14), Vector2(15, 14), Color("#d8ff9a"), 3.0)
		"buggy":
			draw_colored_polygon(PackedVector2Array([Vector2(-38, 36), Vector2(-30, 2), Vector2(16, -3), Vector2(37, 15), Vector2(34, 38)]), vehicle_color)
			draw_polyline(PackedVector2Array([Vector2(-38, 36), Vector2(-30, 2), Vector2(16, -3), Vector2(37, 15)]), Color("#b9e7ff"), 4.0)
			for x in range(-26, 28, 13): draw_line(Vector2(x, 7), Vector2(x + 12, 36), Color(0.05, 0.2, 0.35, 0.55), 3.0)
			for wheel_x in [-25.0, 25.0]:
				draw_circle(Vector2(wheel_x, 40), 11.0, Color("#09141e"))
				draw_circle(Vector2(wheel_x, 40), 5.0, Color("#75f2ff"), false, 3.0)
		"rocket":
			var flame_length := 22.0 + absf(sin(Time.get_ticks_msec() * 0.018)) * 18.0 + (16.0 if boost_time > 0.0 else 0.0)
			for nozzle_x in [-18.0, 18.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(nozzle_x - 8, 29), Vector2(nozzle_x, 38 + flame_length), Vector2(nozzle_x + 8, 29)]), Color("#ff623d"))
				draw_colored_polygon(PackedVector2Array([Vector2(nozzle_x - 4, 30), Vector2(nozzle_x, 32 + flame_length * 0.65), Vector2(nozzle_x + 4, 30)]), Color("#fff27a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-38, 27), Vector2(-28, 0), Vector2(0, -17), Vector2(28, 0), Vector2(38, 27), Vector2(25, 37), Vector2(-25, 37)]), vehicle_color)
			draw_polyline(PackedVector2Array([Vector2(-38, 27), Vector2(-28, 0), Vector2(0, -17), Vector2(28, 0), Vector2(38, 27)]), Color("#fff1ad"), 4.0)
			draw_circle(Vector2(0, 5), 10.0, Color("#17334b"))
			draw_circle(Vector2(0, 5), 6.0, Color("#8ef4ff"))
	_draw_ability_texture()
	var line_color := Color(body_color, pulse)
	var outline := Color(0.015, 0.045, 0.06, pulse)
	draw_circle(Vector2(0, -30), 18.0, Color(body_color, 0.12))
	draw_circle(Vector2(0, -30), 15.0, outline, false, 11.0)
	draw_line(Vector2(0, -15), Vector2(0, 19), outline, 13.0, true)
	draw_line(Vector2(0, -7), Vector2(-19 - stride * 0.35, 8), outline, 12.0, true)
	var weapon_hand := Vector2(direction.x * 29.0, -4)
	draw_line(Vector2(0, -7), weapon_hand, outline, 12.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), outline, 13.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), outline, 13.0, true)
	if skin_shape == "orbit":
		draw_circle(Vector2(0, -28), 24.0, Color(body_color, 0.16), false, 5.0)
		draw_circle(Vector2(22, -30 + sin(walk_phase) * 4.0), 5.0, Color("#ffd166"))
	if skin_shape == "square":
		draw_rect(Rect2(-15, -44, 30, 28), line_color, false, 6.0)
	else:
		draw_circle(Vector2(0, -30), 14.0, line_color, false, 6.0)
	if skin_shape == "cap":
		draw_line(Vector2(-13, -45), Vector2(13, -45), line_color, 6.0, true)
		draw_line(Vector2(8, -44), Vector2(21, -39), line_color, 5.0, true)
	elif skin_shape == "hood":
		draw_polyline(PackedVector2Array([Vector2(-18, -23), Vector2(-16, -48), Vector2(0, -57), Vector2(16, -48), Vector2(18, -23)]), line_color, 5.0, true)
		draw_line(Vector2(12, -22), Vector2(29, -9), line_color, 5.0, true)
	draw_line(Vector2(0, -15), Vector2(0, 19), line_color, 7.0, true)
	draw_line(Vector2(0, -7), Vector2(-19 - stride * 0.35, 8), line_color, 6.0, true)
	draw_line(Vector2(0, -7), weapon_hand, line_color, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), line_color, 7.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), line_color, 7.0, true)
	for joint in [Vector2(0, -7), Vector2(0, 18), weapon_hand]:
		draw_circle(joint, 4.5, Color("#f5f0d7"))
	if design == "visor":
		draw_line(Vector2(-10, -31), Vector2(10, -31), Color("#10232d"), 5.0, true)
	elif design == "bolt":
		draw_polyline(PackedVector2Array([Vector2(-4, -39), Vector2(3, -32), Vector2(-3, -25), Vector2(5, -20)]), Color("#fff3a3"), 3.0)
	draw_circle(weapon_hand, 4.0, Color("#f5f0d7"))
	_draw_weapon(weapon_hand, direction.x)

func _draw_weapon(hand: Vector2, side: float) -> void:
	var tip := hand + Vector2(side * 43.0, -4.0)
	match weapon_id:
		"dagger":
			draw_colored_polygon(PackedVector2Array([hand, tip + Vector2(0, -8), tip + Vector2(side * 17, 0), tip + Vector2(0, 8)]), Color("#d9dfd7"))
			draw_polyline(PackedVector2Array([hand, tip + Vector2(0, -8), tip + Vector2(side * 17, 0), tip + Vector2(0, 8), hand]), Color("#fff4bd"), 3.0)
			draw_line(hand + Vector2(side * 9, -7), hand + Vector2(side * 9, 7), Color("#6f3526"), 6.0)
			for i in range(3): draw_circle(hand + Vector2(side * (18 + i * 10), -3 + i * 3), 3.0, Color("#b95532"))
		"bat":
			draw_line(hand, tip + Vector2(side * 17, -4), Color("#b37a48"), 16.0, true)
			for i in range(4): draw_line(hand + Vector2(side * (7 + i * 7), -9), hand + Vector2(side * (12 + i * 7), 7), Color("#fff0c7"), 4.0)
		"bow":
			draw_arc(hand + Vector2(side * 21, 0), 31.0, -PI * 0.5, PI * 0.5, 16, Color("#71efc0"), 7.0)
			draw_line(hand + Vector2(side * 21, -31), hand + Vector2(side * 21, 31), Color("#fff7dc"), 3.0)
		"flame":
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 44.0), -13), Vector2(44, 26)), Color("#d9573e"), true)
			for i in range(4): draw_line(hand + Vector2(side * (7 + i * 9), -11), hand + Vector2(side * (13 + i * 9), 11), Color("#ffb14f"), 4.0)
			draw_line(hand + Vector2(side * 8, -7), tip + Vector2(side * 12, 0), Color("#fff06d"), 7.0)
		_:
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 47.0), -13), Vector2(47, 26)), Color("#315f8f"), true)
			draw_rect(Rect2(hand + Vector2(minf(0.0, side * 42.0), -9), Vector2(42, 8)), Color("#9ff8ff"), true)
			for i in range(3): draw_circle(hand + Vector2(side * (11 + i * 12), 6), 3.5, Color("#d6ff77"))

func _draw_ability_texture() -> void:
	var pulse := 0.65 + sin(Time.get_ticks_msec() * 0.007) * 0.2
	match ability_style:
		"burst":
			for radius in [31.0, 39.0, 47.0]: draw_arc(Vector2(0, -7), radius, -2.7, -0.45, 12, Color(1.0, 0.35, 0.16, pulse * 0.55), 4.0)
		"vine":
			draw_arc(Vector2(0, -5), 39.0, 0.1, PI * 1.6, 18, Color("#72e57d"), 5.0)
			for angle in [0.4, 1.2, 2.1]: draw_circle(Vector2.RIGHT.rotated(angle) * 39.0 + Vector2(0, -5), 5.0, Color("#b3ff85"))
		"blink":
			for i in range(5): draw_rect(Rect2(-45 + i * 19, -62 + (i % 2) * 12, 9, 9), Color(0.56, 0.48, 1.0, pulse), true)
		"inferno":
			for i in range(8): draw_line(Vector2.RIGHT.rotated(i * TAU / 8.0) * 34.0 + Vector2(0, -7), Vector2.RIGHT.rotated(i * TAU / 8.0) * 50.0 + Vector2(0, -7), Color("#ffb640"), 6.0)
		"flight":
			var wing_alpha := 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.2
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -5), Vector2(-48, -36), Vector2(-30, 10)]), Color(0.5, 0.82, 1.0, wing_alpha))
			draw_colored_polygon(PackedVector2Array([Vector2(4, -5), Vector2(48, -36), Vector2(30, 10)]), Color(0.5, 0.82, 1.0, wing_alpha))
