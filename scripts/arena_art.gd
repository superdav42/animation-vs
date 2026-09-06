extends Node2D

var elapsed := 0.0
var branch_anchors: Array[Vector2] = []

func _ready() -> void:
	var size := get_viewport_rect().size
	branch_anchors = [
		Vector2(104, size.y * 0.31), Vector2(176, size.y * 0.25),
		Vector2(size.x - 105, size.y * 0.37), Vector2(size.x - 180, size.y * 0.29),
	]
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func snap_vine_start(point: Vector2) -> Vector2:
	var best := Vector2(point.x, clampf(point.y, 150.0, get_viewport_rect().size.y - 105.0))
	var distance := 90.0
	for anchor in branch_anchors:
		var candidate := point.distance_to(anchor)
		if candidate < distance:
			best = anchor
			distance = candidate
	return best

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#081922"))
	for i in range(12):
		var y := 120.0 + i * 100.0
		draw_line(Vector2(35, y), Vector2(size.x - 35, y), Color(0.12, 0.34, 0.36, 0.18), 1.0)
	for i in range(9):
		var x := 40.0 + i * 86.0
		draw_line(Vector2(x, 120), Vector2(x, size.y - 90), Color(0.12, 0.34, 0.36, 0.14), 1.0)

	for i in range(24):
		var seed := float(i)
		var point := Vector2(fposmod(i * 137.0, size.x - 100.0) + 50.0, fposmod(i * 193.0, size.y - 260.0) + 145.0)
		var alpha := 0.12 + sin(elapsed * 0.9 + seed) * 0.05
		draw_circle(point, 2.0 + i % 3, Color(0.32, 0.9, 0.72, alpha))

	_draw_tree(Vector2(32, size.y * 0.2), 1.0, false)
	_draw_tree(Vector2(size.x - 32, size.y * 0.25), 0.92, true)
	draw_rect(Rect2(28, 112, size.x - 56, size.y - 192), Color(0.2, 0.8, 0.66, 0.07), false, 4.0)

func _draw_tree(root: Vector2, scale_factor: float, mirrored: bool) -> void:
	var side := -1.0 if mirrored else 1.0
	var trunk_end := root + Vector2(side * 22.0, 760.0) * scale_factor
	draw_line(root, trunk_end, Color("#213c35"), 42.0 * scale_factor, true)
	for i in range(4):
		var start := root.lerp(trunk_end, 0.14 + i * 0.19)
		var finish := start + Vector2(side * (145.0 - i * 12.0), -55.0 + i * 12.0) * scale_factor
		draw_line(start, finish, Color("#2d5944"), 17.0 * scale_factor, true)
		for leaf in range(3):
			var leaf_pos := start.lerp(finish, 0.48 + leaf * 0.2)
			draw_circle(leaf_pos, (16.0 - leaf * 2.0) * scale_factor, Color("#267d57"))
