extends Control

var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#07121e"))
	for band in range(9):
		var band_rect := Rect2(0.0, size.y * float(band) / 9.0, size.x, size.y / 9.0 + 2.0)
		draw_rect(band_rect, Color(0.025 + band * 0.004, 0.07 + band * 0.009, 0.12 + band * 0.012, 1.0))

	for i in range(18):
		var x := fposmod(float(i * 173) + sin(elapsed * 0.18 + i) * 24.0, size.x + 80.0) - 40.0
		var y := fposmod(float(i * 251), size.y * 0.72) + 30.0
		var pulse := 0.45 + sin(elapsed * 1.2 + i) * 0.18
		draw_circle(Vector2(x, y), 2.0 + float(i % 3), Color(0.35, 0.86, 0.78, pulse))

	var horizon := size.y * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 90), Vector2(size.x * 0.18, horizon - 55),
		Vector2(size.x * 0.4, horizon + 20), Vector2(size.x * 0.62, horizon - 105),
		Vector2(size.x * 0.82, horizon - 25), Vector2(size.x, horizon - 80),
		Vector2(size.x, size.y), Vector2(0, size.y),
	]), Color("#102d3b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 145), Vector2(size.x * 0.24, horizon + 25),
		Vector2(size.x * 0.5, horizon + 115), Vector2(size.x * 0.78, horizon - 5),
		Vector2(size.x, horizon + 75), Vector2(size.x, size.y), Vector2(0, size.y),
	]), Color("#0b222c"))

	for ring in range(4):
		var radius := 150.0 + ring * 76.0 + sin(elapsed * 0.45 + ring) * 8.0
		draw_arc(Vector2(size.x * 0.5, size.y * 0.79), radius, PI, TAU, 40, Color(0.18, 0.56, 0.54, 0.12), 2.0)

	_draw_branch(Vector2(-20, size.y * 0.25), Vector2(size.x * 0.25, size.y * 0.34), 22.0)
	_draw_branch(Vector2(size.x + 20, size.y * 0.18), Vector2(size.x * 0.72, size.y * 0.31), 18.0)

func _draw_branch(start: Vector2, finish: Vector2, width: float) -> void:
	draw_line(start, finish, Color("#294439"), width, true)
	var direction := (finish - start).normalized()
	var normal := direction.rotated(PI * 0.5)
	for i in range(1, 5):
		var point := start.lerp(finish, i / 5.0)
		var twig_end := point + normal * (34.0 + i * 7.0) * (-1.0 if i % 2 == 0 else 1.0)
		draw_line(point, twig_end, Color("#38614b"), width * 0.35, true)
		draw_circle(twig_end, 9.0, Color("#43a66d"))
