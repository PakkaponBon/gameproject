extends Node
## Autoload: single source of truth for the tile grid — walkability (one
## grid per agent kind: gates are open to villagers, solid to enemies),
## buildings, stockpile zones, and which cell each ground item occupies.

signal zones_changed  # stockpiles or fields repainted

const MAP_SIZE := Vector2i(96, 96)  # open-world scale (was 64); scatter scales with area
const TILE_SIZE := 16
const INVALID_CELL := Vector2i(-1, -1)

var astar := AStarGrid2D.new()        # villager pathing
var astar_enemy := AStarGrid2D.new()  # enemy pathing (gates count as solid)
var buildings := {}  # Vector2i -> building id (String)
var building_hp := {}  # Vector2i -> remaining HP (damageable buildings only)
var stockpile_cells := {}  # Set of Vector2i (value unused)
var fields := {}  # Vector2i -> crop id (String)
var safety_cells := {}  # Set of Vector2i: where undrafted villagers flee in raids
var items := {}  # Vector2i -> Node2D occupying that cell
var reserved_storage := {}  # Set of Vector2i claimed as a haul destination
var indoor_cells := {}  # Set of Vector2i sealed off from the map edge (rooms)
var warmth_sources := {}  # Vector2i -> radius (hearth, brazier)
var comfort_sources := {}  # Vector2i -> comfort value (furniture)
var traps := {}  # Vector2i -> remaining uses (spike pits)

func _ready() -> void:
	for grid: AStarGrid2D in [astar, astar_enemy]:
		grid.region = Rect2i(Vector2i.ZERO, MAP_SIZE)
		grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()

## Wipe all grid state (used when loading a save into a fresh scene).
func reset() -> void:
	buildings.clear()
	building_hp.clear()
	stockpile_cells.clear()
	fields.clear()
	safety_cells.clear()
	items.clear()
	reserved_storage.clear()
	indoor_cells.clear()
	warmth_sources.clear()
	comfort_sources.clear()
	traps.clear()
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
	if def.has("hp"):
		building_hp[cell] = float(def.hp)
	astar.set_point_solid(cell, def.block_villagers)
	astar_enemy.set_point_solid(cell, def.block_enemies)
	if def.has("warmth_radius"):
		warmth_sources[cell] = int(def.warmth_radius)
	if def.has("comfort"):
		comfort_sources[cell] = int(def.comfort)
	if def.has("trap_damage"):
		traps[cell] = int(def.trap_uses)
	if def.block_villagers or def.block_enemies:
		_recompute_rooms()
	if def.storage:
		stockpile_cells[cell] = true
		zones_changed.emit()

func remove_building(cell: Vector2i) -> void:
	if not buildings.has(cell):
		return
	var def: Dictionary = BuildingDefs.get_def(buildings[cell])
	buildings.erase(cell)
	building_hp.erase(cell)
	astar.set_point_solid(cell, false)
	astar_enemy.set_point_solid(cell, false)
	warmth_sources.erase(cell)
	comfort_sources.erase(cell)
	traps.erase(cell)
	if def.block_villagers or def.block_enemies:
		_recompute_rooms()
	if def.storage:
		stockpile_cells.erase(cell)
		zones_changed.emit()

## An enemy stepped here: if it's a trap, the spikes bite. Spent traps
## are destroyed through the normal building_destroyed path.
func trigger_trap(cell: Vector2i, victim: Node) -> void:
	if not traps.has(cell) or not buildings.has(cell):
		return
	var def: Dictionary = BuildingDefs.get_def(buildings[cell])
	traps[cell] = int(traps[cell]) - 1
	EventBus.play_sfx.emit("hit")
	victim.take_damage(float(def.trap_damage))  # may free the victim
	if traps.has(cell) and int(traps[cell]) <= 0:
		EventBus.building_destroyed.emit(cell)

## Damage a breakable building. Emits building_destroyed at 0 HP.
func damage_building(cell: Vector2i, amount: float) -> void:
	if not building_hp.has(cell):
		return
	building_hp[cell] = float(building_hp[cell]) - amount
	if float(building_hp[cell]) <= 0.0:
		EventBus.building_destroyed.emit(cell)

## Solid to everyone (ore nodes etc.) — not a building, no registry entry.
func set_obstacle(cell: Vector2i, solid: bool) -> void:
	if in_bounds(cell):
		astar.set_point_solid(cell, solid)
		astar_enemy.set_point_solid(cell, solid)
		_recompute_rooms()  # ore can seal a room; mining it out unseals

## Rooms: flood the outside in from the map edge; any cell the flood can't
## reach (and doesn't itself seal) is indoors. Sealing = solid to enemies,
## so walls, closed doors, and gates all hold the warmth in.
func _recompute_rooms() -> void:
	indoor_cells.clear()
	var outside := {}
	var stack: Array[Vector2i] = []
	for x in MAP_SIZE.x:
		for cell: Vector2i in [Vector2i(x, 0), Vector2i(x, MAP_SIZE.y - 1)]:
			if not _seals_room(cell) and not outside.has(cell):
				outside[cell] = true
				stack.append(cell)
	for y in MAP_SIZE.y:
		for cell: Vector2i in [Vector2i(0, y), Vector2i(MAP_SIZE.x - 1, y)]:
			if not _seals_room(cell) and not outside.has(cell):
				outside[cell] = true
				stack.append(cell)
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := cell + dir
			if in_bounds(next) and not outside.has(next) and not _seals_room(next):
				outside[next] = true
				stack.append(next)
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var cell := Vector2i(x, y)
			if not outside.has(cell) and not _seals_room(cell):
				indoor_cells[cell] = true

func _seals_room(cell: Vector2i) -> bool:
	return astar_enemy.is_point_solid(cell)

func is_indoors(cell: Vector2i) -> bool:
	return indoor_cells.has(cell)

## Within any hearth/brazier's square radius?
func is_warm_spot(cell: Vector2i) -> bool:
	for src: Vector2i in warmth_sources:
		var radius: int = warmth_sources[src]
		if absi(cell.x - src.x) <= radius and absi(cell.y - src.y) <= radius:
			return true
	return false

## Furniture comfort within reach of a cell (capped — a palace of chairs
## is still just cozy).
func comfort_at(cell: Vector2i) -> float:
	var total := 0.0
	for src: Vector2i in comfort_sources:
		if absi(cell.x - src.x) <= 4 and absi(cell.y - src.y) <= 4:
			total += float(comfort_sources[src])
	return minf(total, 6.0)

## A reachable spot at/next to the best furniture — breaks and festival
## evenings gather villagers here.
func best_comfort_spot(from_cell: Vector2i) -> Vector2i:
	var best := INVALID_CELL
	var best_score := -INF
	for src: Vector2i in comfort_sources:
		var score := comfort_at(src) * 100.0 - float((src - from_cell).length_squared())
		if score <= best_score:
			continue
		for dir: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var spot := src + dir
			if in_bounds(spot) and not is_wall(spot) \
					and not astar.get_id_path(from_cell, spot).is_empty():
				best = spot
				best_score = score
				break
	return best

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

const STACK_MAX := 4  # items of one kind a single stockpile tile can hold

func register_item(cell: Vector2i, item: Node2D) -> void:
	if not items.has(cell):
		items[cell] = []
	(items[cell] as Array).append(item)

func unregister_item(cell: Vector2i, item: Node2D) -> void:
	if not items.has(cell):
		return
	var stack: Array = items[cell]
	stack.erase(item)
	if stack.is_empty():
		items.erase(cell)

## How many items sit on a cell (0 if none) — drives the stack visual.
func item_count(cell: Vector2i) -> int:
	return (items[cell] as Array).size() if items.has(cell) else 0

func reserve_storage(cell: Vector2i) -> void:
	reserved_storage[cell] = true

func release_storage(cell: Vector2i) -> void:
	reserved_storage.erase(cell)

## A stockpile tile takes an item if it's empty, or already holds the same
## resource with room in the stack (pass the kind to allow stacking).
func is_cell_free_for_storage(cell: Vector2i, kind := "") -> bool:
	if not is_stockpile(cell) or is_wall(cell) or reserved_storage.has(cell):
		return false
	if not items.has(cell):
		return true
	if kind == "":
		return false  # occupied and the caller isn't stacking
	var stack: Array = items[cell]
	return stack.size() < STACK_MAX and (stack[0] as ResourceItem).resource_id == kind

## Nearest reachable stockpile cell that will take an item of `kind` (empty,
## or a matching stack with room). INVALID_CELL if none.
func get_free_stockpile_cell(from_cell: Vector2i, kind := "") -> Vector2i:
	var best := INVALID_CELL
	var best_dist := INF
	for cell: Vector2i in stockpile_cells:
		if not is_cell_free_for_storage(cell, kind):
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
