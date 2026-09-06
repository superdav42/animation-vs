extends Node2D

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var growth := 0.0
var linger := 2.3
var damage := 50.0
var touched: Array[int] = []
var team := "player"

func setup(from: Vector2, to: Vector2, vine_damage: float, vine_team := "player") -> void:
	start_point = from
	end_point = to
	damage = vine_damage
	team = vine_team

func _ready() -> void:
	add_to_group("vines")
	queue_redraw()

func _process(delta: float) -> void:
	growth = minf(1.0, growth + delta * 0.72)
	if growth >= 1.0:
		linger -= delta
		if linger <= 0.0:
			queue_free()
	_hurt_crossed_targets()
	queue_redraw()

func _hurt_crossed_targets() -> void:
	var tip := start_point.lerp(end_point, growth)
	var target_group := "cpu" if team == "player" else "player"
	for target in get_tree().get_nodes_in_group(target_group):
		if not is_instance_valid(target):
			continue
		var identity := target.get_instance_id()
		if identity in touched:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(target.global_position, start_point, tip)
		if target.global_position.distance_to(closest) < 38.0:
			touched.append(identity)
			target.take_damage(damage)
			if is_instance_valid(target) and target.has_method("slow"):
				target.slow(3.0, 0.45)

func _draw() -> void:
	var points := PackedVector2Array()
	var count := maxi(2, int(22 * growth))
	var current_end := start_point.lerp(end_point, growth)
	var direction := start_point.direction_to(end_point)
	var normal := direction.rotated(PI * 0.5)
	for i in range(count + 1):
		var t := float(i) / count
		var wave := sin(t * 19.0) * 9.0 * sin(t * PI)
		points.append(start_point.lerp(current_end, t) + normal * wave)
	var dark := Color("#421c42") if team == "cpu" else Color("#173e2d")
	var bright := Color("#e060b2") if team == "cpu" else Color("#54c86d")
	draw_polyline(points, dark, 18.0, true)
	draw_polyline(points, bright, 9.0, true)
	for i in range(3, points.size(), 4):
		var leaf_direction := normal * (1.0 if i % 2 == 0 else -1.0)
		draw_line(points[i], points[i] + leaf_direction * 19.0, Color("#76e47d"), 6.0, true)
		draw_circle(points[i] + leaf_direction * 22.0, 7.0, Color("#95f28d"))
