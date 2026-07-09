extends Node
## Autoload: global pool of available jobs. Pawns request the best job for
## their priorities and reserve it so no two pawns work the same job.

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var jobs: Array[Job] = []

## Wipe the pool (used when loading a save; entities re-register their jobs).
func reset() -> void:
	jobs.clear()

func add_job(job: Job) -> void:
	jobs.append(job)

func remove_job(job: Job) -> void:
	jobs.erase(job)

## Best = lowest priority number first (0 disables the job type entirely),
## then nearest by distance. Only reachable, currently-valid jobs count.
func request_job(from_cell: Vector2i, priorities: Dictionary) -> Job:
	# Haul jobs are only valid while somewhere exists to put the item.
	var storage_available := WorldGrid.get_free_stockpile_cell(from_cell) != WorldGrid.INVALID_CELL
	var supply_checked := false
	var supply_ok := false
	var best: Job = null
	var best_prio := 0
	var best_dist := INF
	for job in jobs:
		if job.reserved:
			continue
		# SUPPLY is hauling work; DECONSTRUCT is construction work.
		var prio_type := job.type
		if job.type == Job.Type.SUPPLY:
			prio_type = Job.Type.HAUL
		elif job.type == Job.Type.DECONSTRUCT:
			prio_type = Job.Type.BUILD
		var prio: int = priorities.get(prio_type, 1)
		if prio <= 0:
			continue
		if job.type == Job.Type.HAUL:
			if not storage_available:
				continue
			if (job.target as WoodItem).reserved:
				continue  # claimed as blueprint material
		if job.type == Job.Type.SUPPLY:
			# Supply jobs are only valid while fetchable wood exists.
			if not supply_checked:
				supply_checked = true
				supply_ok = find_fetchable_wood(from_cell) != null
			if not supply_ok:
				continue
		if best and (prio > best_prio or (prio == best_prio and float((job.cell - from_cell).length_squared()) >= best_dist)):
			continue
		# Solid targets (e.g. deconstructing a wall) are worked from beside.
		var reachable := nearest_work_spot(from_cell, job.cell) != WorldGrid.INVALID_CELL \
				if job.type == Job.Type.DECONSTRUCT else _is_reachable(from_cell, job.cell)
		if reachable:
			best = job
			best_prio = prio
			best_dist = float((job.cell - from_cell).length_squared())
	if best:
		best.reserved = true
	return best

## Nearest reachable wood a supplier may take: not reserved as material,
## not being carried, and not claimed by a hauler.
func find_fetchable_wood(from_cell: Vector2i) -> WoodItem:
	var best: WoodItem = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("wood"):
		var wood := node as WoodItem
		if wood.reserved or wood.get_parent() is Pawn:
			continue
		if wood.haul_job and wood.haul_job.reserved:
			continue
		var dist := float((wood.cell - from_cell).length_squared())
		if dist < best_dist and _is_reachable(from_cell, wood.cell):
			best = wood
			best_dist = dist
	return best

## Nearest walkable, reachable cell to work a target from: the target's own
## cell if it isn't solid, otherwise one of its neighbors. INVALID_CELL if none.
func nearest_work_spot(from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	var best := WorldGrid.INVALID_CELL
	var best_len := INF
	for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var spot := target_cell + offset
		if not WorldGrid.in_bounds(spot) or WorldGrid.is_wall(spot):
			continue
		var path := WorldGrid.astar.get_id_path(from_cell, spot)
		if not path.is_empty() and path.size() < best_len:
			best = spot
			best_len = path.size()
	return best

func release_job(job: Job) -> void:
	job.reserved = false

func complete_job(job: Job) -> void:
	jobs.erase(job)
	job.completed.emit()

func _is_reachable(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return not WorldGrid.astar.get_id_path(from_cell, to_cell).is_empty()
