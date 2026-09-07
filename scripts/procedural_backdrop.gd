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
	var arena_id: String = Progress.selected_arena
	var base := Color("#07121e")
	var accent := Color("#43d9bd")
	match arena_id:
		"moon_dojo":
			base = Color("#111426")
			accent = Color("#ffd166")
		"ember_foundry":
			base = Color("#180f18")
			accent = Color("#ff704f")
		"crystal_cavern":
			base = Color("#0c1026")
			accent = Color("#a889ff")
	draw_rect(Rect2(Vector2.ZERO, size), base)
	for band in range(9):
		var band_rect := Rect2(0.0, size.y * float(band) / 9.0, size.x, size.y / 9.0 + 2.0)
		draw_rect(band_rect, base.lightened(0.012 * band))

	for i in range(18):
		var x := fposmod(float(i * 173) + sin(elapsed * 0.18 + i) * 24.0, size.x + 80.0) - 40.0
		var y := fposmod(float(i * 251), size.y * 0.72) + 30.0
		var pulse := 0.45 + sin(elapsed * 1.2 + i) * 0.18
		draw_circle(Vector2(x, y), 2.0 + float(i % 3), Color(accent, pulse))

	var horizon := size.y * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 90), Vector2(size.x * 0.18, horizon - 55),
		Vector2(size.x * 0.4, horizon + 20), Vector2(size.x * 0.62, horizon - 105),
		Vector2(size.x * 0.82, horizon - 25), Vector2(size.x, horizon - 80),
		Vector2(size.x, size.y), Vector2(0, size.y),
	]), base.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 145), Vector2(size.x * 0.24, horizon + 25),
		Vector2(size.x * 0.5, horizon + 115), Vector2(size.x * 0.78, horizon - 5),
		Vector2(size.x, horizon + 75), Vector2(size.x, size.y), Vector2(0, size.y),
	]), base.lightened(0.055))

	match arena_id:
		"moon_dojo":
			draw_circle(Vector2(size.x * 0.8, size.y * 0.18), 112.0, Color("#ffe7a0"))
			draw_circle(Vector2(size.x * 0.75, size.y * 0.145), 112.0, base)
			_draw_gate(Vector2(75, size.y * 0.69), Color("#b55746"))
		"ember_foundry":
			for pipe_x in [45.0, size.x - 45.0]:
				draw_line(Vector2(pipe_x, size.y * 0.16), Vector2(pipe_x, size.y * 0.82), Color("#593139"), 34.0)
				for y in range(260, int(size.y * 0.8), 150): draw_circle(Vector2(pipe_x, y), 8.0, Color("#ff8b55"))
			for i in range(18):
				var spark := Vector2(fposmod(i * 89.0 + elapsed * 19.0, size.x), size.y * 0.2 + fposmod(i * 71.0 - elapsed * 28.0, size.y * 0.6))
				draw_line(spark, spark + Vector2(5, -13), Color("#ffc15c"), 3.0)
		"crystal_cavern":
			for crystal_x in [70.0, 155.0, size.x - 75.0]: _draw_crystal(Vector2(crystal_x, size.y * 0.85), accent)
		_:
			for ring in range(4):
				var radius := 150.0 + ring * 76.0 + sin(elapsed * 0.45 + ring) * 8.0
				draw_arc(Vector2(size.x * 0.5, size.y * 0.79), radius, PI, TAU, 40, Color(accent, 0.12), 2.0)
			_draw_branch(Vector2(-20, size.y * 0.25), Vector2(size.x * 0.25, size.y * 0.34), 22.0)
			_draw_branch(Vector2(size.x + 20, size.y * 0.18), Vector2(size.x * 0.72, size.y * 0.31), 18.0)

func _draw_gate(position: Vector2, color: Color) -> void:
	draw_line(position + Vector2(-52, 0), position + Vector2(-52, 220), color, 20.0)
	draw_line(position + Vector2(52, 0), position + Vector2(52, 220), color, 20.0)
	draw_line(position + Vector2(-88, 18), position + Vector2(88, 18), color.lightened(0.16), 25.0)
	draw_line(position + Vector2(-70, 52), position + Vector2(70, 52), color, 12.0)

func _draw_crystal(base: Vector2, color: Color) -> void:
	for offset in [-22.0, 0.0, 24.0]:
		var height := 100.0 + absf(offset)
		var shape := PackedVector2Array([base + Vector2(offset - 14, 0), base + Vector2(offset - 9, -height * 0.65), base + Vector2(offset, -height), base + Vector2(offset + 12, -height * 0.6), base + Vector2(offset + 15, 0)])
		draw_colored_polygon(shape, Color(color, 0.55))
		draw_polyline(shape, color.lightened(0.25), 3.0)

func _draw_branch(start: Vector2, finish: Vector2, width: float) -> void:
	draw_line(start, finish, Color("#294439"), width, true)
	var direction := (finish - start).normalized()
	var normal := direction.rotated(PI * 0.5)
	for i in range(1, 5):
		var point := start.lerp(finish, i / 5.0)
		var twig_end := point + normal * (34.0 + i * 7.0) * (-1.0 if i % 2 == 0 else 1.0)
		draw_line(point, twig_end, Color("#38614b"), width * 0.35, true)
		draw_circle(twig_end, 9.0, Color("#43a66d"))
