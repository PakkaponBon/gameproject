extends Camera2D

@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.25
@export var max_zoom: float = 4.0

func _process(delta: float) -> void:
	var dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	# Divide by zoom so panning feels the same speed on screen at any zoom level.
	position += dir * pan_speed * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.0 + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 / (1.0 + zoom_step))

func _apply_zoom(factor: float) -> void:
	var new_zoom := clampf(zoom.x * factor, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, zoom.x):
		return
	# Keep the world point under the cursor fixed while zooming.
	var mouse_offset := get_viewport().get_mouse_position() - get_viewport_rect().size / 2.0
	position += mouse_offset * (1.0 / zoom.x - 1.0 / new_zoom)
	zoom = Vector2(new_zoom, new_zoom)
