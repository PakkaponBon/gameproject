class_name PawnWork
extends Node
## Colony-job execution for one pawn: claiming jobs from the pool and the
## chop/haul/supply/build behaviors. Movement and needs live on the pawn.

const FOOD_SCENE := preload("res://scenes/food_item.tscn")

var job: Job = null
var carrying: WoodItem = null
var fetching: WoodItem = null  # supply leg 1: walking to pick this up
var fetching_food: FoodItem = null  # feed leg 1
var carrying_food := false  # feed leg 2: meal in hand
var reserved_dest := WorldGrid.INVALID_CELL  # claimed stockpile cell while hauling
var work_progress := 0.0  # fractional work from speed modifiers

@onready var pawn: Pawn = get_parent()

func busy() -> bool:
	return job != null or carrying != null or fetching != null \
			or fetching_food != null or carrying_food

func request_next() -> void:
	job = JobManager.request_job(pawn.cell, pawn.work_priorities)
	if job == null:
		return
	if job.type == Job.Type.SUPPLY:
		_ensure_fetch()
	elif job.type == Job.Type.FEED:
		_ensure_food_fetch()
	elif job.type == Job.Type.DECONSTRUCT:
		_approach_deconstruct()
	else:
		pawn.target_cell = job.cell

func on_arrived() -> void:
	if fetching:
		_pick_up_fetched()
	elif fetching_food:
		_pick_up_food()
	elif carrying_food:
		_deliver_food()
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
	if is_instance_valid(fetching_food):
		fetching_food.reserved = false
	fetching_food = null
	if carrying_food:
		_drop_food_in_hand()
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
		Job.Type.FEED:
			_ensure_food_fetch()
		Job.Type.DECONSTRUCT:
			_do_deconstruct()
		Job.Type.PLANT:
			# Field unzoned or winter arrived while we walked here.
			if not WorldGrid.fields.has(job.cell) or (job.target as FieldKeeper).is_winter():
				job = null
				return
			_apply_work()
			if job.work_ticks <= 0:
				JobManager.complete_job(job)
				job = null
		Job.Type.CHOP, Job.Type.BUILD, Job.Type.HARVEST:
			if not is_instance_valid(job.target):  # e.g. blueprint canceled, crop frosted
				job = null
				return
			_apply_work()
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
	_apply_work()
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

func _ensure_food_fetch() -> void:
	var food := JobManager.find_fetchable_food(pawn.cell)
	if food == null:
		abort()  # food ran out; the pool filters re-grabs
		return
	food.reserved = true
	fetching_food = food
	pawn.target_cell = food.cell

func _pick_up_food() -> void:
	if job == null or not is_instance_valid(fetching_food):
		fetching_food = null
		abort()
		return
	fetching_food.queue_free()  # into our hands
	fetching_food = null
	carrying_food = true
	pawn.target_cell = job.cell

func _deliver_food() -> void:
	carrying_food = false
	if job == null:  # e.g. relink failed after load; leave the meal here
		_drop_food_in_hand()
		return
	var patient := job.target as Pawn
	job = null
	if is_instance_valid(patient) and patient.collapsed and patient.feed_job:
		JobManager.complete_job(patient.feed_job)  # patient stands up via be_fed
	else:
		_drop_food_in_hand()  # died or recovered meanwhile; leave the meal here

func _drop_food_in_hand() -> void:
	carrying_food = false
	var food: Node2D = FOOD_SCENE.instantiate()
	food.position = WorldGrid.cell_to_world(pawn.cell)
	pawn.get_parent().get_node("Entities").add_child(food)

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

## Advance the held job by this tick's work, scaled by condition:
## exhaustion halves speed, low mood scales down to 60%.
func _apply_work() -> void:
	var speed := pawn.needs.mood_work_factor()
	if pawn.needs.is_exhausted():
		speed *= 0.5
	work_progress += speed
	while work_progress >= 1.0:
		work_progress -= 1.0
		job.work_ticks -= 1

func _release_dest() -> void:
	if reserved_dest != WorldGrid.INVALID_CELL:
		WorldGrid.release_storage(reserved_dest)
		reserved_dest = WorldGrid.INVALID_CELL
