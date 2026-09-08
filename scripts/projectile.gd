extends Node2D

var direction := Vector2.UP
var speed := 800.0
var damage := 25.0
var lifetime := 1.2
var pierce := 1
var color := Color("#62e6ff")
var team := "player"
var hit_targets: Array[int] = []
var weapon_id := ""

func setup(heading: Vector2, weapon_data: Dictionary, item_id: String, projectile_team := "player") -> void:
	direction = heading.normalized()
	damage = float(weapon_data.get("damage", 25.0))
	team = projectile_team
	weapon_id = item_id
	speed = 870.0 if weapon_data.get("pierce", 1) > 1 else 720.0
	pierce = int(weapon_data.get("pierce", 1))
	color = Color("#ff6c9f") if team == "cpu" else (Color("#78b8ff") if item_id == "blaster" else Color("#c8ff72"))
	rotation = direction.angle()

func _ready() -> void:
	add_to_group("projectiles")
	queue_redraw()

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func hit(target: Node) -> void:
	var identity := target.get_instance_id()
	if identity in hit_targets:
		return
	hit_targets.append(identity)
	target.take_damage(damage)
	pierce -= 1
	if pierce <= 0:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-34, 0), Vector2(9, 0), Color(color, 0.1), 22.0, true)
	draw_line(Vector2(-28, 0), Vector2(9, 0), Color(color, 0.28), 13.0, true)
	draw_line(Vector2(-18, 0), Vector2(8, 0), Color(color, 0.72), 5.0, true)
	match weapon_id:
		"popgun", "pebbler":
			draw_circle(Vector2(8, 0), 14.0, Color(color, 0.18))
			draw_circle(Vector2(8, 0), 9.0, color)
			draw_circle(Vector2(8, 0), 5.0, Color("#27343b"))
			draw_circle(Vector2(8, 0), 2.0, Color.WHITE)
		"bow", "disc":
			draw_line(Vector2(-15, 0), Vector2(17, 0), color, 5.0, true)
			draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(8, -7), Vector2(8, 7)]), Color.WHITE)
			draw_line(Vector2(-8, -5), Vector2(-2, 0), Color("#d9ffea"), 2.0)
			draw_line(Vector2(-8, 5), Vector2(-2, 0), Color("#d9ffea"), 2.0)
		_:
			draw_line(Vector2(-12, 0), Vector2(14, 0), color, 7.0, true)
			for x in [-7.0, 2.0, 11.0]: draw_circle(Vector2(x, 0), 2.4, Color.WHITE)
			draw_arc(Vector2(14, 0), 8.0, -PI * 0.7, PI * 0.7, 9, Color(color, 0.75), 3.0)
