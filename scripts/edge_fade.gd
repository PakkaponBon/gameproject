extends Node2D
## Darkens the world's rim so the map doesn't end in a hard line.

const STEPS := 3
const STEP_PX := 14.0

func _draw() -> void:
	var size := Vector2(WorldGrid.MAP_SIZE) * WorldGrid.TILE_SIZE
	for i in STEPS:
		var inset := STEP_PX * i
		var alpha := 0.28 - 0.08 * i
		var color := Color(0.04, 0.03, 0.05, alpha)
		draw_rect(Rect2(inset, inset, size.x - inset * 2, STEP_PX), color)  # top
		draw_rect(Rect2(inset, size.y - inset - STEP_PX, size.x - inset * 2, STEP_PX), color)  # bottom
		draw_rect(Rect2(inset, inset + STEP_PX, STEP_PX, size.y - (inset + STEP_PX) * 2), color)  # left
		draw_rect(Rect2(size.x - inset - STEP_PX, inset + STEP_PX, STEP_PX, size.y - (inset + STEP_PX) * 2), color)  # right
