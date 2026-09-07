extends Node2D

var elapsed := 0.0
var branch_anchors: Array[Vector2] = []
var arena_id := "neon_forest"

func configure(selected_arena: String) -> void:
	arena_id = selected_arena if selected_arena in GearCatalog.ARENAS else "neon_forest"
	queue_redraw()

func ground_y() -> float:
	return get_viewport_rect().size.y - 245.0

func _ready() -> void:
	var size := get_viewport_rect().size
	branch_anchors = [
		Vector2(104, size.y * 0.36), Vector2(176, size.y * 0.3),
		Vector2(size.x - 105, size.y * 0.42), Vector2(size.x - 180, size.y * 0.34),
	]
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func snap_vine_start(point: Vector2) -> Vector2:
	var best := Vector2(point.x, clampf(point.y, 250.0, ground_y()))
	var distance := 90.0
	for anchor in branch_anchors:
		var candidate := point.distance_to(anchor)
		if candidate < distance:
			best = anchor
			distance = candidate
	return best

func _draw() -> void:
	var size := get_viewport_rect().size
	match arena_id:
		"moon_dojo": _draw_moon_dojo(size)
		"ember_foundry": _draw_ember_foundry(size)
		"crystal_cavern": _draw_crystal_cavern(size)
		_: _draw_neon_forest(size)

func _draw_neon_forest(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#081922"))
	_draw_depth_grid(size, Color(0.12, 0.34, 0.36, 0.16))
	for i in range(24):
		var point := Vector2(fposmod(i * 137.0, size.x - 100.0) + 50.0, fposmod(i * 193.0, ground_y() - 260.0) + 210.0)
		var alpha := 0.12 + sin(elapsed * 0.9 + float(i)) * 0.05
		draw_circle(point, 2.0 + i % 3, Color(0.32, 0.9, 0.72, alpha))
	_draw_tree(Vector2(32, size.y * 0.2), 1.0, false)
	_draw_tree(Vector2(size.x - 32, size.y * 0.25), 0.92, true)
	_draw_floor(size, Color("#102f32"), Color("#43d9bd"), "roots")

func _draw_moon_dojo(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101629"))
	for band in range(7):
		draw_rect(Rect2(0, band * ground_y() / 7.0, size.x, ground_y() / 7.0 + 2.0), Color(0.07 + band * 0.008, 0.09 + band * 0.008, 0.16 + band * 0.012))
	draw_circle(Vector2(size.x * 0.72, 350), 126.0, Color("#f8e8b0"))
	draw_circle(Vector2(size.x * 0.68, 325), 126.0, Color("#101629"))
	for layer in range(3):
		var base_y := 610.0 + layer * 80.0
		var mountain := PackedVector2Array([Vector2(0, base_y), Vector2(130, base_y - 130 + layer * 20), Vector2(250, base_y - 35), Vector2(390, base_y - 180 + layer * 25), Vector2(550, base_y - 55), Vector2(size.x, base_y - 145), Vector2(size.x, ground_y()), Vector2(0, ground_y())])
		draw_colored_polygon(mountain, Color(0.12 + layer * 0.025, 0.14 + layer * 0.025, 0.22 + layer * 0.025))
	_draw_torii(Vector2(90, ground_y() - 330), 0.72)
	_draw_torii(Vector2(size.x - 92, ground_y() - 280), 0.55)
	for x in [150.0, size.x - 150.0]:
		draw_line(Vector2(x, ground_y() - 170), Vector2(x, ground_y() - 40), Color("#553a35"), 9.0)
		draw_circle(Vector2(x, ground_y() - 180), 24.0, Color(1.0, 0.58, 0.25, 0.22))
		draw_rect(Rect2(x - 13, ground_y() - 195, 26, 30), Color("#e88748"), true)
	_draw_floor(size, Color("#332c36"), Color("#dfb86b"), "planks")

func _draw_ember_foundry(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#160f18"))
	for i in range(6):
		var x := 34.0 + i * 138.0
		draw_rect(Rect2(x, 260, 76, ground_y() - 260), Color("#251b25"), true)
		draw_rect(Rect2(x + 10, 300, 56, ground_y() - 350), Color("#3b2730"), false, 7.0)
	for x in [115.0, size.x - 115.0]:
		draw_circle(Vector2(x, ground_y() - 250), 82.0, Color("#4a2524"))
		draw_circle(Vector2(x, ground_y() - 250), 55.0, Color("#ff6c3f"))
		draw_circle(Vector2(x, ground_y() - 250), 34.0 + sin(elapsed * 2.0) * 5.0, Color("#ffd05d"))
	for i in range(30):
		var spark_x := fposmod(i * 83.0 + elapsed * (12.0 + i % 5), size.x)
		var spark_y := ground_y() - fposmod(i * 57.0 + elapsed * (35.0 + i % 4), 580.0)
		draw_line(Vector2(spark_x, spark_y), Vector2(spark_x + 4, spark_y - 10), Color(1.0, 0.45, 0.18, 0.55), 2.0)
	draw_line(Vector2(0, 480), Vector2(size.x, 480), Color("#49323d"), 36.0)
	for x in range(30, int(size.x), 70):
		draw_circle(Vector2(x, 480), 6.0, Color("#a75a4c"))
	_draw_floor(size, Color("#34242b"), Color("#ff704f"), "plates")

func _draw_crystal_cavern(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0b1025"))
	var cave := PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, ground_y()), Vector2(size.x - 70, 720), Vector2(size.x - 20, 520), Vector2(size.x - 115, 360), Vector2(size.x - 70, 170), Vector2(size.x * 0.55, 235), Vector2(size.x * 0.35, 120), Vector2(90, 230), Vector2(0, 180)])
	draw_colored_polygon(cave, Color("#161b38"))
	for i in range(18):
		var point := Vector2(fposmod(i * 151.0, size.x), 210.0 + fposmod(i * 91.0, ground_y() - 350.0))
		draw_circle(point, 28.0 + i % 4 * 8.0, Color(0.25, 0.2, 0.5, 0.08))
	for crystal in [Vector2(80, ground_y()), Vector2(165, ground_y()), Vector2(size.x - 80, ground_y()), Vector2(size.x - 175, ground_y())]:
		_draw_crystal_cluster(crystal)
	for i in range(20):
		var mist := Vector2(fposmod(i * 119.0 + elapsed * 9.0, size.x), 340.0 + fposmod(i * 67.0, 530.0))
		draw_circle(mist, 4.0 + i % 3, Color(0.55, 0.45, 1.0, 0.2))
	_draw_floor(size, Color("#202044"), Color("#a889ff"), "facets")

func _draw_depth_grid(size: Vector2, color: Color) -> void:
	for i in range(10):
		var y := 180.0 + i * 82.0
		draw_line(Vector2(35, y), Vector2(size.x - 35, y), color, 1.0)
	for i in range(9):
		var x := 40.0 + i * 86.0
		draw_line(Vector2(x, 180), Vector2(x, ground_y()), color, 1.0)

func _draw_floor(size: Vector2, base: Color, accent: Color, texture_style: String) -> void:
	var floor_top := ground_y()
	draw_rect(Rect2(0, floor_top, size.x, size.y - floor_top), base, true)
	draw_line(Vector2(0, floor_top), Vector2(size.x, floor_top), accent, 8.0)
	for i in range(11):
		var x := i * size.x / 10.0
		match texture_style:
			"planks": draw_line(Vector2(x, floor_top), Vector2(x + (x - size.x * 0.5) * 0.22, size.y), Color(accent, 0.22), 3.0)
			"plates":
				draw_line(Vector2(x, floor_top), Vector2(x, size.y), Color(accent, 0.18), 2.0)
				draw_circle(Vector2(x + 10, floor_top + 38 + (i % 3) * 44), 4.0, Color(accent, 0.45))
			"facets": draw_line(Vector2(x, floor_top), Vector2(x + 45.0 * (-1.0 if i % 2 == 0 else 1.0), size.y), Color(accent, 0.2), 2.0)
			_: draw_line(Vector2(x, floor_top), Vector2(x - 45 + sin(float(i)) * 25, size.y), Color(accent, 0.16), 3.0)

func _draw_torii(position: Vector2, scale_factor: float) -> void:
	draw_line(position + Vector2(-55, 0) * scale_factor, position + Vector2(-55, 250) * scale_factor, Color("#753e3d"), 22.0 * scale_factor)
	draw_line(position + Vector2(55, 0) * scale_factor, position + Vector2(55, 250) * scale_factor, Color("#753e3d"), 22.0 * scale_factor)
	draw_line(position + Vector2(-92, 18) * scale_factor, position + Vector2(92, 18) * scale_factor, Color("#a44d42"), 26.0 * scale_factor)
	draw_line(position + Vector2(-74, 48) * scale_factor, position + Vector2(74, 48) * scale_factor, Color("#d0674d"), 13.0 * scale_factor)

func _draw_crystal_cluster(base: Vector2) -> void:
	for offset in [-28.0, 0.0, 30.0]:
		var height := 90.0 + absf(offset) * 1.2
		var crystal := PackedVector2Array([base + Vector2(offset - 16, 0), base + Vector2(offset - 11, -height * 0.68), base + Vector2(offset, -height), base + Vector2(offset + 13, -height * 0.62), base + Vector2(offset + 17, 0)])
		draw_colored_polygon(crystal, Color(0.45, 0.34, 0.9, 0.72))
		draw_polyline(crystal, Color("#c3b3ff"), 3.0)

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
