extends Node
## Autoload: single source of truth for the tile grid and walkability.

const MAP_SIZE := Vector2i(64, 64)
const TILE_SIZE := 16

var astar := AStarGrid2D.new()

func _ready() -> void:
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

func in_bounds(cell: Vector2i) -> bool:
	return astar.region.has_point(cell)

func is_wall(cell: Vector2i) -> bool:
	return in_bounds(cell) and astar.is_point_solid(cell)

func set_wall(cell: Vector2i, solid: bool) -> void:
	if in_bounds(cell):
		astar.set_point_solid(cell, solid)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2.ONE * (TILE_SIZE / 2.0)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / TILE_SIZE).floor())
