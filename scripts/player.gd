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

func configure(data: Dictionary, equipped_vehicle: String) -> void:
	vehicle_id = equipped_vehicle
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
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down") if keyboard_enabled else Vector2.ZERO
	var movement := mobile_vector if mobile_vector.length_squared() > keyboard.length_squared() else keyboard
	if movement.length_squared() > 0.0:
		movement = movement.normalized()
		facing = movement
	var speed := base_speed * (boost_multiplier if boost_time > 0.0 else 1.0)
	velocity = movement * speed
	move_and_slide()
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
	if boost_cooldown > 0.0:
		return false
	boost_time = 0.55
	boost_cooldown = 3.0
	return true

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, 150.0, size.y - 110.0))
	invulnerable_time = 0.7

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
	draw_circle(Vector2.ZERO, 22.0, Color(0.98, 0.95, 0.78, pulse))
	draw_circle(Vector2(-7, -4), 3.0, Color("#132331"))
	draw_circle(Vector2(7, -4), 3.0, Color("#132331"))
	draw_line(Vector2(-6, 8), Vector2(6, 8), Color("#132331"), 2.0)
	draw_line(direction * 18.0 + side * 9.0, direction * 36.0 + side * 7.0, Color("#f8f0cb"), 5.0, true)
