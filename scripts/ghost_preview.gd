extends Node2D
## Placement preview: tints the cell under the mouse green (valid) or red
## (invalid) while a build/zone tool is active. Rendering only.

@onready var main: Node2D = get_parent()
@onready var input_ctrl: PlayerInput = main.get_node("PlayerInput")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if input_ctrl.mode == PlayerInput.Mode.COMMAND:
		return
	var cell := input_ctrl.mouse_cell()
	if not WorldGrid.in_bounds(cell):
		return
	var valid := input_ctrl.placement_valid(cell)
	var color := Color(0.3, 0.9, 0.4, 0.35) if valid else Color(0.95, 0.25, 0.2, 0.4)
	var rect := Rect2(Vector2(cell) * WorldGrid.TILE_SIZE, Vector2.ONE * WorldGrid.TILE_SIZE)
	draw_rect(rect, color)
	draw_rect(rect, Color(color, 0.9), false, 1.0)
