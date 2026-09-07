extends Control

signal changed(value: Vector2)

var active := false
var pointer_id := -1
var origin := Vector2.ZERO
var knob := Vector2.ZERO
var radius := 72.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			_begin(event.index, event.position)
		elif not event.pressed and event.index == pointer_id:
			_end()
	elif event is InputEventScreenDrag and event.index == pointer_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(0, event.position)
		elif pointer_id == 0:
			_end()
	elif event is InputEventMouseMotion and active and pointer_id == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_knob(event.position)

func _begin(id: int, position: Vector2) -> void:
	active = true
	pointer_id = id
	origin = position
	knob = position
	changed.emit(Vector2.ZERO)
	queue_redraw()

func _update_knob(position: Vector2) -> void:
	var offset := position - origin
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob = origin + offset
	var value := offset / radius
	if value.length() < 0.12:
		value = Vector2.ZERO
	changed.emit(value)
	queue_redraw()

func _end() -> void:
	active = false
	pointer_id = -1
	changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(origin, radius, Color(0.03, 0.1, 0.14, 0.72))
	draw_circle(origin, radius, Color("#6ce6bb"), false, 5.0)
	draw_circle(knob, 34.0, Color(0.24, 0.78, 0.62, 0.92))
	draw_circle(knob, 34.0, Color("#d8ffe9"), false, 4.0)
