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

func configure(data: Dictionary, equipped_vehicle: String, skin_data := {}, fighter_color := Color("#63e6bc"), fighter_design := "classic") -> void:
	vehicle_id = equipped_vehicle
	body_color = fighter_color
	skin_shape = skin_data.get("shape", "round")
	design = fighter_design
	base_speed = float(data.get("speed", 360.0))
	boost_multiplier = float(data.get("boost", 1.35))
	max_health = 100.0 + float(data.get("armor", 0))
	health = max_health
	health_changed.emit(health, max_health)
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
	if movement.length_squared() > 0.0:
		movement = movement.normalized()
		facing = movement
	var speed := base_speed * (boost_multiplier if boost_time > 0.0 else 1.0)
	if slow_time > 0.0:
		speed *= slow_multiplier
	velocity = movement * speed
	move_and_slide()
	walk_phase += velocity.length() * delta * 0.035
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 48.0, size.x - 48.0)
	global_position.y = clampf(global_position.y, 145.0, size.y - 105.0)
	queue_redraw()

func set_mobile_vector(value: Vector2) -> void:
	mobile_vector = value

func set_aim(point: Vector2) -> void:
	var direction := global_position.direction_to(point)
	if direction.length_squared() > 0.01:
		facing = direction

func try_boost() -> bool:
	if vehicle_id.is_empty() or boost_cooldown > 0.0:
		return false
	boost_time = 0.55
	boost_cooldown = 3.0
	return true

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, 150.0, size.y - 110.0))
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
	var side := direction.rotated(PI * 0.5)
	var stride := sin(walk_phase) * (8.0 if velocity.length_squared() > 10.0 else 1.5)
	draw_set_transform(Vector2.ZERO, direction.angle() + PI * 0.5)
	match vehicle_id:
		"board":
			draw_line(Vector2(-25, 23), Vector2(25, 23), vehicle_color, 12.0, true)
			draw_circle(Vector2(-20, 29), 6.0, Color("#08131d"))
			draw_circle(Vector2(20, 29), 6.0, Color("#08131d"))
		"bike":
			draw_circle(Vector2(-23, 24), 13.0, Color("#102632"), false, 4.0)
			draw_circle(Vector2(23, 24), 13.0, Color("#102632"), false, 4.0)
			draw_line(Vector2(-22, 24), Vector2(7, 4), vehicle_color, 6.0, true)
			draw_line(Vector2(7, 4), Vector2(23, 24), vehicle_color, 6.0, true)
		"buggy":
			draw_rect(Rect2(-32, 4, 64, 36), vehicle_color, true)
			draw_circle(Vector2(-25, 40), 9.0, Color("#09141e"))
			draw_circle(Vector2(25, 40), 9.0, Color("#09141e"))
		"rocket":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(27, 31), Vector2(0, 20), Vector2(-27, 31)]), vehicle_color)
			draw_colored_polygon(PackedVector2Array([Vector2(-12, 29), Vector2(0, 52 + sin(Time.get_ticks_msec() * 0.02) * 5), Vector2(12, 29)]), Color("#ff5d5d"))
	draw_set_transform(Vector2.ZERO, 0.0)
	var line_color := Color(body_color, pulse)
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
	var weapon_hand := direction * 29.0 + Vector2(0, -4)
	draw_line(Vector2(0, -7), weapon_hand, line_color, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), line_color, 7.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), line_color, 7.0, true)
	if design == "visor":
		draw_line(Vector2(-10, -31), Vector2(10, -31), Color("#10232d"), 5.0, true)
	elif design == "bolt":
		draw_polyline(PackedVector2Array([Vector2(-4, -39), Vector2(3, -32), Vector2(-3, -25), Vector2(5, -20)]), Color("#fff3a3"), 3.0)
	draw_circle(weapon_hand, 4.0, Color("#f5f0d7"))
