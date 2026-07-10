extends Node
## Autoload: single source of truth for the tile grid — walkability (one
## grid per agent kind: gates are open to villagers, solid to enemies),
## buildings, stockpile zones, and which cell each ground item occupies.

signal zones_changed  # stockpiles or fields repainted

const MAP_SIZE := Vector2i(64, 64)
const TILE_SIZE := 16
const INVALID_CELL := Vector2i(-1, -1)

var astar := AStarGrid2D.new()        # villager pathing
var astar_enemy := AStarGrid2D.new()  # enemy pathing (gates count as solid)
var buildings := {}  # Vector2i -> building id (String)
var stockpile_cells := {}  # Set of Vector2i (value unused)
var fields := {}  # Vector2i -> crop id (String)
var safety_cells := {}  # Set of Vector2i: where undrafted villagers flee in raids
var items := {}  # Vector2i -> Node2D occupying that cell
var reserved_storage := {}  # Set of Vector2i claimed as a haul destination

func _ready() -> void:
	for grid: AStarGrid2D in [astar, astar_enemy]:
		grid.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
		grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()

## Wipe all grid state (used when loading a save into a fresh scene).
func reset() -> void:
	buildings.clear()
	stockpile_cells.clear()
	fields.clear()
	safety_cells.clear()
	items.clear()
	reserved_storage.clear()
	astar.fill_solid_region(astar.region, false)
	astar_enemy.fill_solid_region(astar_enemy.region, false)
	zones_changed.emit()

func in_bounds(cell: Vector2i) -> bool:
	return astar.region.has_point(cell)

## "Wall" = blocks villagers. Enemies additionally treat gates as walls.
func is_wall(cell: Vector2i) -> bool:
	return in_bounds(cell) and astar.is_point_solid(cell)

func register_building(cell: Vector2i, id: String) -> void:
	if not in_bounds(cell):
		return
	var def: Dictionary = BuildingDefs.get_def(id)
	buildings[cell] = id
	astar.set_point_solid(cell, def.block_villagers)
	astar_enemy.set_point_solid(cell, def.block_enemies)
	if def.storage:
		stockpile_cells[cell] = true
		zones_changed.emit()

func remove_building(cell: Vector2i) -> void:
	if not buildings.has(cell):
		return
	var def: Dictionary = BuildingDefs.get_def(buildings[cell])
	buildings.erase(cell)
	astar.set_point_solid(cell, false)
	astar_enemy.set_point_solid(cell, false)
	if def.storage:
		stockpile_cells.erase(cell)
		zones_changed.emit()

## Solid to everyone (ore nodes etc.) — not a building, no registry entry.
func set_obstacle(cell: Vector2i, solid: bool) -> void:
	if in_bounds(cell):
		astar.set_point_solid(cell, solid)
		astar_enemy.set_point_solid(cell, solid)

func set_stockpile(cell: Vector2i, on: bool) -> void:
	if not in_bounds(cell) or (on and (is_wall(cell) or fields.has(cell))):
		return
	if on:
		stockpile_cells[cell] = true
	else:
		stockpile_cells.erase(cell)
	zones_changed.emit()

func set_field(cell: Vector2i, crop_id: String) -> void:
	if not in_bounds(cell) or is_wall(cell) or buildings.has(cell) or stockpile_cells.has(cell):
		return
	fields[cell] = crop_id
	zones_changed.emit()

func remove_field(cell: Vector2i) -> void:
	fields.erase(cell)
	zones_changed.emit()

func set_safety(cell: Vector2i, on: bool) -> void:
	if not in_bounds(cell) or (on and is_wall(cell)):
		return
	if on:
		safety_cells[cell] = true
	else:
		safety_cells.erase(cell)
	zones_changed.emit()

func nearest_safety_cell(from_cell: Vector2i) -> Vector2i:
	var best := INVALID_CELL
	var best_dist := INF
	for cell: Vector2i in safety_cells:
		if is_wall(cell):
			continue
		var dist := float((cell - from_cell).length_squared())
		if dist < best_dist and not astar.get_id_path(from_cell, cell).is_empty():
			best = cell
			best_dist = dist
	return best

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
