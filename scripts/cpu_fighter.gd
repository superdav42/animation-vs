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

func configure(loadout: Dictionary, chase_target: Node2D, player_color := Color("#63e6bc"), player_design := "classic", player_shape := "round") -> void:
	target = chase_target
	weapon_id = loadout["weapons"]
	vehicle_id = loadout["vehicles"]
	ability_id = loadout["abilities"]
	weapon_data = loadout["weapon_data"]
	vehicle_data = loadout["vehicle_data"]
	ability_data = loadout["ability_data"]
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
	max_health = 100.0 + float(vehicle_data.get("armor", 0))
	health = max_health
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
	if not is_instance_valid(target) or health <= 0.0:
		velocity = Vector2.ZERO
		return
	var to_target := global_position.direction_to(target.global_position)
	var distance := global_position.distance_to(target.global_position)
	var desired_range := _desired_range()
	var movement := Vector2.ZERO
	if distance > desired_range + 55.0:
		movement = to_target
	elif distance < desired_range - 35.0:
		movement = -to_target
	else:
		movement = to_target.rotated(PI * 0.5 * strafe_direction) * 0.72
	facing = to_target
	var speed := base_speed * (slow_multiplier if slow_time > 0.0 else 1.0)
	velocity = movement.normalized() * speed
	move_and_slide()
	walk_phase += velocity.length() * delta * 0.035
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 48.0, size.x - 48.0)
	global_position.y = clampf(global_position.y, 145.0, size.y - 105.0)
	queue_redraw()

func _desired_range() -> float:
	match weapon_data.get("style", "projectile"):
		"melee": return 82.0
		"flame": return 175.0
	return 330.0

func teleport_to(point: Vector2) -> void:
	var size := get_viewport_rect().size
	global_position = Vector2(clampf(point.x, 55.0, size.x - 55.0), clampf(point.y, 150.0, size.y - 110.0))
	invulnerable_time = 0.5

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
		draw_set_transform(Vector2.ZERO, facing.angle() + PI * 0.5)
		match vehicle_id:
			"roller":
				draw_line(Vector2(-26, 23), Vector2(26, 23), vehicle_color, 13.0, true)
			"hoverbike":
				draw_circle(Vector2(-24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_circle(Vector2(24, 24), 12.0, Color("#26162e"), false, 4.0)
				draw_line(Vector2(-20, 22), Vector2(24, 8), vehicle_color, 7.0, true)
			"mech":
				draw_rect(Rect2(-33, 4, 66, 38), vehicle_color)
				draw_line(Vector2(-22, 39), Vector2(-29, 52), Color("#40203d"), 9.0)
				draw_line(Vector2(22, 39), Vector2(29, 52), Color("#40203d"), 9.0)
			"saucer":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(34, 24), Vector2(0, 38), Vector2(-34, 24)]), vehicle_color)
		draw_set_transform(Vector2.ZERO, 0.0)
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
	var weapon_hand := facing * 29.0 + Vector2(0, -4)
	draw_line(Vector2(0, -7), weapon_hand, body_color, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-15 - stride, 40), body_color, 7.0, true)
	draw_line(Vector2(0, 18), Vector2(15 + stride, 40), body_color, 7.0, true)
	if design == "visor":
		draw_line(Vector2(-10, -31), Vector2(10, -31), Color("#151527"), 5.0, true)
	elif design == "bolt":
		draw_polyline(PackedVector2Array([Vector2(-4, -39), Vector2(3, -32), Vector2(-3, -25), Vector2(5, -20)]), Color("#fff3a3"), 3.0)
	draw_circle(weapon_hand, 4.0, Color("#ffecf4"))
