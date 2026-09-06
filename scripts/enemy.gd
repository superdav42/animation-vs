extends CharacterBody2D

signal died(reward: int, at_position: Vector2)

var target: Node2D
var health := 40.0
var max_health := 40.0
var move_speed := 115.0
var contact_damage := 9.0
var reward := 5
var kind := 0
var hit_cooldown := 0.0
var slow_time := 0.0
var slow_multiplier := 1.0

func configure(wave: int, chase_target: Node2D) -> void:
	target = chase_target
	kind = mini(3, wave / 3)
	max_health = 30.0 + wave * 7.0 + kind * 12.0
	health = max_health
	move_speed = 95.0 + wave * 5.0 + kind * 8.0
	contact_damage = 7.0 + wave * 0.9
	reward = 4 + wave + kind * 2
	queue_redraw()

func _ready() -> void:
	add_to_group("enemies")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 23.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	slow_time = maxf(0.0, slow_time - delta)
	if not is_instance_valid(target):
		return
	var multiplier := slow_multiplier if slow_time > 0.0 else 1.0
	velocity = global_position.direction_to(target.global_position) * move_speed * multiplier
	move_and_slide()
	if global_position.distance_to(target.global_position) < 55.0 and hit_cooldown <= 0.0:
		if target.has_method("take_damage"):
			target.take_damage(contact_damage)
		hit_cooldown = 0.8
	queue_redraw()

func take_damage(amount: float) -> void:
	health -= amount
	queue_redraw()
	if health <= 0.0:
		died.emit(reward, global_position)
		queue_free()

func slow(duration: float, multiplier: float) -> void:
	slow_time = maxf(slow_time, duration)
	slow_multiplier = minf(slow_multiplier, multiplier)

func _draw() -> void:
	var colors := [Color("#ef5d75"), Color("#e779cc"), Color("#ad74f3"), Color("#ff7047")]
	var color: Color = colors[kind]
	draw_circle(Vector2.ZERO, 24.0 + kind * 2.0, Color(0.02, 0.07, 0.1, 0.8))
	for spike in range(8):
		var direction := Vector2.UP.rotated(spike * TAU / 8.0)
		draw_colored_polygon(PackedVector2Array([direction.rotated(-0.2) * 20.0, direction * (32.0 + kind * 3.0), direction.rotated(0.2) * 20.0]), color)
	draw_circle(Vector2.ZERO, 20.0, color)
	draw_circle(Vector2(-7, -3), 4.0, Color("#101821"))
	draw_circle(Vector2(7, -3), 4.0, Color("#101821"))
	var health_width := 46.0 * clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-23, -39, 46, 5), Color(0.05, 0.08, 0.1, 0.8))
	draw_rect(Rect2(-23, -39, health_width, 5), Color("#61e3a5"))
