extends Node2D
## Draws the stockpile zone as translucent rectangles. Pure rendering;
## the zone data lives in WorldGrid.

const FILL := Color(1.0, 0.85, 0.3, 0.22)
const BORDER := Color(1.0, 0.85, 0.3, 0.6)

func _ready() -> void:
	WorldGrid.stockpile_changed.connect(queue_redraw)

func _draw() -> void:
	for cell: Vector2i in WorldGrid.stockpile_cells:
		var rect := Rect2(Vector2(cell) * WorldGrid.TILE_SIZE, Vector2.ONE * WorldGrid.TILE_SIZE)
		draw_rect(rect, FILL)
		draw_rect(rect, BORDER, false, 1.0)
