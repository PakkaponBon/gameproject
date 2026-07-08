extends Node
## Autoload: global pool of available jobs. Pawns request the nearest
## reachable job and reserve it so no two pawns work the same job.

var jobs: Array[Job] = []

func add_job(job: Job) -> void:
	jobs.append(job)

func remove_job(job: Job) -> void:
	jobs.erase(job)

func request_job(from_cell: Vector2i) -> Job:
	# Haul jobs are only valid while somewhere exists to put the item.
	var storage_available := WorldGrid.get_free_stockpile_cell(from_cell) != WorldGrid.INVALID_CELL
	var best: Job = null
	var best_dist := INF
	for job in jobs:
		if job.reserved:
			continue
		if job.type == Job.Type.HAUL and not storage_available:
			continue
		var dist := float((job.cell - from_cell).length_squared())
		if dist < best_dist and _is_reachable(from_cell, job.cell):
			best = job
			best_dist = dist
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
