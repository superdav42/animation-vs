extends Node2D

var direction := Vector2.UP
var speed := 800.0
var damage := 25.0
var lifetime := 1.2
var pierce := 1
var color := Color("#62e6ff")
var team := "player"
var hit_targets: Array[int] = []

func setup(heading: Vector2, weapon_data: Dictionary, weapon_id: String, projectile_team := "player") -> void:
	direction = heading.normalized()
	damage = float(weapon_data.get("damage", 25.0))
	team = projectile_team
	speed = 870.0 if weapon_data.get("pierce", 1) > 1 else 720.0
	pierce = int(weapon_data.get("pierce", 1))
	color = Color("#ff6c9f") if team == "cpu" else (Color("#78b8ff") if weapon_id == "blaster" else Color("#c8ff72"))
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
	draw_line(Vector2(-20, 0), Vector2(8, 0), Color(color, 0.35), 10.0, true)
	draw_line(Vector2(-10, 0), Vector2(12, 0), color, 5.0, true)
	draw_circle(Vector2(12, 0), 5.0, Color.WHITE)
