extends Node
## Autoload: global pool of available jobs. Pawns request the best job for
## their priorities and reserve it so no two pawns work the same job.

var jobs: Array[Job] = []

## Wipe the pool (used when loading a save; entities re-register their jobs).
func reset() -> void:
	jobs.clear()

func add_job(job: Job) -> void:
	jobs.append(job)

func remove_job(job: Job) -> void:
	jobs.erase(job)

## Best = lowest priority number first (0 disables the job type entirely),
## then nearest by distance. Only reachable jobs are considered.
func request_job(from_cell: Vector2i, priorities: Dictionary) -> Job:
	# Haul jobs are only valid while somewhere exists to put the item.
	var storage_available := WorldGrid.get_free_stockpile_cell(from_cell) != WorldGrid.INVALID_CELL
	var best: Job = null
	var best_prio := 0
	var best_dist := INF
	for job in jobs:
		if job.reserved:
			continue
		var prio: int = priorities.get(job.type, 1)
		if prio <= 0:
			continue
		if job.type == Job.Type.HAUL and not storage_available:
			continue
		if best and (prio > best_prio or (prio == best_prio and float((job.cell - from_cell).length_squared()) >= best_dist)):
			continue
		if _is_reachable(from_cell, job.cell):
			best = job
			best_prio = prio
			best_dist = float((job.cell - from_cell).length_squared())
	if best:
		best.reserved = true
	return best

func release_job(job: Job) -> void:
	job.reserved = false

func complete_job(job: Job) -> void:
	jobs.erase(job)
	job.completed.emit()

func _is_reachable(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return not WorldGrid.astar.get_id_path(from_cell, to_cell).is_empty()
