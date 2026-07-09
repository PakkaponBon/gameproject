extends Node2D
## Draws stockpile and field zones as translucent rectangles. Pure
## rendering; the zone data lives in WorldGrid.

const STOCK_FILL := Color(1.0, 0.85, 0.3, 0.22)
const STOCK_BORDER := Color(1.0, 0.85, 0.3, 0.6)
const FIELD_FILL := Color(0.5, 0.75, 0.3, 0.2)
const FIELD_BORDER := Color(0.5, 0.75, 0.3, 0.55)

func _ready() -> void:
	WorldGrid.zones_changed.connect(queue_redraw)

func _draw() -> void:
	for cell: Vector2i in WorldGrid.stockpile_cells:
		_draw_cell(cell, STOCK_FILL, STOCK_BORDER)
	for cell: Vector2i in WorldGrid.fields:
		_draw_cell(cell, FIELD_FILL, FIELD_BORDER)

func _draw_cell(cell: Vector2i, fill: Color, border: Color) -> void:
	var rect := Rect2(Vector2(cell) * WorldGrid.TILE_SIZE, Vector2.ONE * WorldGrid.TILE_SIZE)
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 1.0)
