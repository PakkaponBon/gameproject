extends Node
## Autoload: single source of truth for the tile grid — walkability,
## stockpile zones, and which cell each ground item occupies.

signal stockpile_changed

const MAP_SIZE := Vector2i(64, 64)
const TILE_SIZE := 16
const INVALID_CELL := Vector2i(-1, -1)

var astar := AStarGrid2D.new()
var stockpile_cells := {}  # Set of Vector2i (value unused)
var items := {}  # Vector2i -> Node2D occupying that cell
var reserved_storage := {}  # Set of Vector2i claimed as a haul destination

func _ready() -> void:
	astar.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
	astar.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

## Wipe all grid state (used when loading a save into a fresh scene).
func reset() -> void:
	stockpile_cells.clear()
	items.clear()
	reserved_storage.clear()
	astar.fill_solid_region(astar.region, false)
	stockpile_changed.emit()

func in_bounds(cell: Vector2i) -> bool:
	return astar.region.has_point(cell)

func is_wall(cell: Vector2i) -> bool:
	return in_bounds(cell) and astar.is_point_solid(cell)

func set_wall(cell: Vector2i, solid: bool) -> void:
	if in_bounds(cell):
		astar.set_point_solid(cell, solid)

func set_stockpile(cell: Vector2i, on: bool) -> void:
	if not in_bounds(cell) or (on and is_wall(cell)):
		return
	if on:
		stockpile_cells[cell] = true
	else:
		stockpile_cells.erase(cell)
	stockpile_changed.emit()

func is_stockpile(cell: Vector2i) -> bool:
	return stockpile_cells.has(cell)

func register_item(cell: Vector2i, item: Node2D) -> void:
	items[cell] = item

func unregister_item(cell: Vector2i) -> void:
	items.erase(cell)

func reserve_storage(cell: Vector2i) -> void:
	reserved_storage[cell] = true

func release_storage(cell: Vector2i) -> void:
	reserved_storage.erase(cell)

func is_cell_free_for_storage(cell: Vector2i) -> bool:
	return is_stockpile(cell) and not items.has(cell) \
		and not reserved_storage.has(cell) and not is_wall(cell)

## Nearest reachable stockpile cell with no item on it, or INVALID_CELL.
func get_free_stockpile_cell(from_cell: Vector2i) -> Vector2i:
	var best := INVALID_CELL
	var best_dist := INF
	for cell: Vector2i in stockpile_cells:
		if not is_cell_free_for_storage(cell):
			continue
		var dist := float((cell - from_cell).length_squared())
		if dist < best_dist and not astar.get_id_path(from_cell, cell).is_empty():
			best = cell
			best_dist = dist
	return best

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2.ONE * (TILE_SIZE / 2.0)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / TILE_SIZE).floor())
