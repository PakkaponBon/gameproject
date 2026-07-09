class_name PawnWork
extends Node
## Colony-job execution for one pawn: claiming jobs from the pool and the
## chop/haul/supply/build behaviors. Movement and needs live on the pawn.

var job: Job = null
var carrying: WoodItem = null
var fetching: WoodItem = null  # supply leg 1: walking to pick this up
var reserved_dest := WorldGrid.INVALID_CELL  # claimed stockpile cell while hauling

@onready var pawn: Pawn = get_parent()

func busy() -> bool:
	return job != null or carrying != null or fetching != null

func request_next() -> void:
	job = JobManager.request_job(pawn.cell, pawn.work_priorities)
	if job == null:
		return
	if job.type == Job.Type.SUPPLY:
		_ensure_fetch()
	elif job.type == Job.Type.DECONSTRUCT:
		_approach_deconstruct()
	else:
		pawn.target_cell = job.cell

func on_arrived() -> void:
	if fetching:
		_pick_up_fetched()
	elif carrying:
		if job and job.type == Job.Type.SUPPLY:
			_deliver_to_site()
		else:
			_deliver_to_stockpile()
	elif job:
		_do_job()

func abort() -> void:
	if job:
		JobManager.release_job(job)
		job = null
	if fetching:
		if is_instance_valid(fetching):
			fetching.reserved = false
		fetching = null
	if carrying:
		carrying.drop_at(pawn.cell)  # drop_at clears its reservation
		carrying = null
	_release_dest()

## Save/load: re-attach carried wood and re-claim the storage destination.
func restore_carry(wood: WoodItem, dest: Vector2i) -> void:
	wood.pick_up(pawn)
	carrying = wood
	if dest != WorldGrid.INVALID_CELL:
		WorldGrid.reserve_storage(dest)
		reserved_dest = dest
		pawn.target_cell = dest

func _do_job() -> void:
	match job.type:
		Job.Type.HAUL:
			_start_storage_carry(job.target as WoodItem)
		Job.Type.SUPPLY:
			_ensure_fetch()  # e.g. right after load: job held, wood not yet chosen
		Job.Type.DECONSTRUCT:
			_do_deconstruct()
		Job.Type.CHOP, Job.Type.BUILD:
			if not is_instance_valid(job.target):  # e.g. blueprint canceled
				job = null
				return
			if _too_tired_this_tick():
				return
			job.work_ticks -= 1
			if job.work_ticks <= 0:
				var work_cell := job.cell
				var was_build := job.type == Job.Type.BUILD
				JobManager.complete_job(job)
				job = null
				if was_build:
					pawn.step_off_wall(work_cell)

func _approach_deconstruct() -> void:
	var spot := JobManager.nearest_work_spot(pawn.cell, job.cell)
	if spot == WorldGrid.INVALID_CELL:
		abort()
		return
	pawn.target_cell = spot

func _do_deconstruct() -> void:
	if not is_instance_valid(job.target):  # order canceled
		job = null
		return
	# Worked from the target's cell or beside it; re-approach otherwise
	# (e.g. after a load, or if a wall rerouted us).
	var d := (job.cell - pawn.cell).abs()
	if d.x + d.y > 1:
		_approach_deconstruct()
		return
	if _too_tired_this_tick():
		return
	job.work_ticks -= 1
	if job.work_ticks <= 0:
		JobManager.complete_job(job)
		job = null

func _ensure_fetch() -> void:
	var wood := JobManager.find_fetchable_wood(pawn.cell)
	if wood == null:
		abort()  # wood ran out since we took the job; pool filters re-grabs
		return
	wood.reserved = true
	fetching = wood
	pawn.target_cell = wood.cell

func _pick_up_fetched() -> void:
	if job == null or not is_instance_valid(fetching):
		fetching = null
		abort()
		return
	fetching.pick_up(pawn)
	carrying = fetching
	fetching = null
	pawn.target_cell = job.cell

func _deliver_to_site() -> void:
	if not is_instance_valid(job.target):
		# Blueprint canceled mid-carry; keep the wood, release the job —
		# next tick the stockpile path takes over.
		job = null
		return
	carrying.queue_free()  # consumed by the blueprint
	carrying = null
	JobManager.complete_job(job)  # blueprint counts the delivery
	job = null

func _start_storage_carry(wood: WoodItem) -> void:
	wood.pick_up(pawn)  # removes its haul job from the pool
	job = null
	var dest := WorldGrid.get_free_stockpile_cell(pawn.cell)
	if dest == WorldGrid.INVALID_CELL:
		wood.drop_at(pawn.cell)  # storage vanished since we took the job
		return
	WorldGrid.reserve_storage(dest)
	reserved_dest = dest
	carrying = wood
	pawn.target_cell = dest

func _deliver_to_stockpile() -> void:
	_release_dest()
	if WorldGrid.is_cell_free_for_storage(pawn.cell):
		carrying.drop_at(pawn.cell)
		carrying = null
		return
	# Destination was filled or unzoned mid-carry; try another cell.
	var dest := WorldGrid.get_free_stockpile_cell(pawn.cell)
	if dest == WorldGrid.INVALID_CELL:
		carrying.drop_at(pawn.cell)
		carrying = null
	else:
		WorldGrid.reserve_storage(dest)
		reserved_dest = dest
		pawn.target_cell = dest

## Exhausted pawns work at half speed: every other tick is lost.
func _too_tired_this_tick() -> bool:
	return pawn.needs.is_exhausted() and GameClock.ticks % 2 == 0

func _release_dest() -> void:
	if reserved_dest != WorldGrid.INVALID_CELL:
		WorldGrid.release_storage(reserved_dest)
		reserved_dest = WorldGrid.INVALID_CELL
