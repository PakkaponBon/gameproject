class_name PawnWork
extends Node
## Colony-job execution for one pawn: claiming jobs from the pool and the
## chop/haul/supply/build behaviors. Movement and needs live on the pawn.

const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")

var job: Job = null
var carrying: ResourceItem = null
var fetching: ResourceItem = null  # supply leg 1: walking to pick this up
var fetching_food: FoodItem = null  # feed leg 1
var carrying_food := false  # feed leg 2: meal in hand
var fetching_herb: ResourceItem = null  # treat leg 1
var carrying_herb := false  # treat leg 2
var reserved_dest := WorldGrid.INVALID_CELL  # claimed stockpile cell while hauling
var work_progress := 0.0  # fractional work from speed modifiers

@onready var pawn: Pawn = get_parent()

func busy() -> bool:
	return job != null or carrying != null or fetching != null \
			or fetching_food != null or carrying_food \
			or fetching_herb != null or carrying_herb

func request_next() -> void:
	job = JobManager.request_job(pawn)
	if job == null:
		return
	if job.type == Job.Type.SUPPLY:
		_ensure_fetch()
	elif job.type == Job.Type.FEED:
		_ensure_food_fetch()
	elif job.type == Job.Type.TREAT:
		_ensure_herb_fetch()
	elif job.type == Job.Type.DECONSTRUCT or job.type == Job.Type.MINE:
		_approach_work_spot()
	else:
		pawn.target_cell = job.cell

func on_arrived() -> void:
	if fetching:
		_pick_up_fetched()
	elif fetching_food:
		_pick_up_food()
	elif carrying_food:
		_deliver_food()
	elif fetching_herb:
		_pick_up_herb()
	elif carrying_herb:
		_deliver_herb()
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
	if is_instance_valid(fetching_herb):
		fetching_herb.reserved = false
	fetching_herb = null
	if carrying_herb:
		_drop_herb_in_hand()
	if carrying:
		carrying.drop_at(pawn.cell)  # drop_at clears its reservation
		carrying = null
	_release_dest()

## Save/load: re-attach a carried item and re-claim the storage destination.
func restore_carry(item: ResourceItem, dest: Vector2i) -> void:
	item.pick_up(pawn)
	carrying = item
	if dest != WorldGrid.INVALID_CELL:
		WorldGrid.reserve_storage(dest)
		reserved_dest = dest
		pawn.target_cell = dest

func _do_job() -> void:
	match job.type:
		Job.Type.HAUL:
			_start_storage_carry(job.target as ResourceItem)
		Job.Type.SUPPLY:
			_ensure_fetch()  # e.g. right after load: job held, wood not yet chosen
		Job.Type.FEED:
			_ensure_food_fetch()
		Job.Type.TREAT:
			_ensure_herb_fetch()
		Job.Type.EQUIP, Job.Type.AMMO, Job.Type.RELIC:
			_claim_here()
		Job.Type.DECONSTRUCT, Job.Type.MINE:
			_do_adjacent_work()
		Job.Type.HUNT:
			_do_hunt()
		Job.Type.PLANT:
			# Field unzoned or winter arrived while we walked here.
			if not WorldGrid.fields.has(job.cell) or (job.target as FieldKeeper).is_winter():
				job = null
				return
			_apply_work()
			if job.work_ticks <= 0:
				JobManager.complete_job(job)
				job = null
		Job.Type.CHOP, Job.Type.BUILD, Job.Type.HARVEST, Job.Type.CRAFT, Job.Type.COOK:
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
					_step_off_wall(work_cell)

## Hunting a moving critter: give chase until adjacent, then a short
## scuffle catches it. The critter wanders, so re-target every tick.
func _do_hunt() -> void:
	var prey := job.target as Critter
	if not is_instance_valid(prey):
		job = null  # already caught by someone, or despawned
		return
	var d := (prey.cell - pawn.cell).abs()
	if d.x + d.y > 1:
		pawn.target_cell = prey.cell  # still running it down
		return
	_apply_work()
	if job.work_ticks <= 0:
		var caught := job
		job = null
		JobManager.complete_job(caught)  # sfx/fx, then...
		if is_instance_valid(prey):
			prey.hunted()  # ...drops the meat

func _approach_work_spot() -> void:
	var spot := JobManager.nearest_work_spot(pawn.cell, job.cell)
	if spot == WorldGrid.INVALID_CELL:
		abort()
		return
	pawn.target_cell = spot

## Deconstruction and mining: solid targets worked from beside.
func _do_adjacent_work() -> void:
	if not is_instance_valid(job.target):  # order canceled
		job = null
		return
	# Worked from the target's cell or beside it; re-approach otherwise
	# (e.g. after a load, or if a wall rerouted us).
	var d := (job.cell - pawn.cell).abs()
	if d.x + d.y > 1:
		_approach_work_spot()
		return
	_apply_work()
	if job.work_ticks <= 0:
		JobManager.complete_job(job)
		job = null

func _ensure_fetch() -> void:
	var item := JobManager.find_fetchable_resource(pawn.cell, job.resource_id)
	if item == null:
		abort()  # material ran out since we took the job; pool filters re-grabs
		return
	item.reserved = true
	fetching = item
	pawn.target_cell = item.cell

func _pick_up_fetched() -> void:
	if job == null or not is_instance_valid(fetching):
		fetching = null
		abort()
		return
	fetching.pick_up(pawn)
	carrying = fetching
	fetching = null
	pawn.target_cell = job.cell

## EQUIP/AMMO/RELIC: pick the item off the ground into gear.
func _claim_here() -> void:
	var item := job.target as ResourceItem
	# Gone, or hauled elsewhere since we set out.
	if not is_instance_valid(item) or item.get_parent() is Pawn or item.cell != job.cell:
		job = null
		return
	item.pick_up(pawn)  # clears its jobs and cell registration
	match job.type:
		Job.Type.EQUIP:
			pawn.combat.equip(item.resource_id)
		Job.Type.AMMO:
			pawn.combat.ammo += int(ResourceDefs.get_def(item.resource_id).shots)
		Job.Type.RELIC:
			pawn.combat.relic_id = item.resource_id
	item.queue_free()  # lives in gear now, not on the ground
	JobManager.complete_job(job)
	job = null

func _ensure_herb_fetch() -> void:
	var herb := JobManager.find_fetchable_resource(pawn.cell, "herb")
	if herb == null:
		abort()
		return
	herb.reserved = true
	fetching_herb = herb
	pawn.target_cell = herb.cell

func _pick_up_herb() -> void:
	if job == null or not is_instance_valid(fetching_herb):
		fetching_herb = null
		abort()
		return
	fetching_herb.pick_up(pawn)
	fetching_herb.queue_free()  # into our hands
	fetching_herb = null
	carrying_herb = true
	_chase_patient()

func _deliver_herb() -> void:
	if job == null:
		_drop_herb_in_hand()
		return
	var patient := job.target as Pawn
	if not is_instance_valid(patient) or patient.dead:
		job = null
		_drop_herb_in_hand()
		return
	# Patients move (bed rest, work); keep chasing until we share a cell.
	if pawn.cell != patient.cell:
		_chase_patient()
		return
	carrying_herb = false
	patient.combat.heal(float(ResourceDefs.get_def("herb").medicine))
	patient.clear_treat_job()
	job = null

func _chase_patient() -> void:
	var patient := job.target as Pawn
	if is_instance_valid(patient):
		pawn.target_cell = patient.cell

func _drop_herb_in_hand() -> void:
	carrying_herb = false
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = "herb"
	item.position = WorldGrid.cell_to_world(pawn.cell)
	pawn.get_parent().add_child(item)  # pawns live in Entities now

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
	pawn.get_parent().add_child(food)  # pawns live in Entities now

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

func _start_storage_carry(item: ResourceItem) -> void:
	item.pick_up(pawn)  # removes its haul job from the pool
	job = null
	var dest := WorldGrid.get_free_stockpile_cell(pawn.cell)
	if dest == WorldGrid.INVALID_CELL:
		item.drop_at(pawn.cell)  # storage vanished since we took the job
		return
	WorldGrid.reserve_storage(dest)
	reserved_dest = dest
	carrying = item
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

## After finishing a build, don't stand inside the new wall.
func _step_off_wall(wall_cell: Vector2i) -> void:
	if not WorldGrid.is_wall(pawn.cell):
		return
	for dir in Pawn.DIRS:
		var next := wall_cell + dir
		if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
			pawn.cell = next
			pawn.target_cell = next
			return

## Advance the held job by this tick's work, scaled by condition:
## exhaustion halves speed, low mood scales down to 60%.
func _apply_work() -> void:
	var speed := pawn.needs.mood_work_factor() * TraitDefs.multiplier(pawn.traits, "work_speed_mult")
	if pawn.needs.is_exhausted():
		speed *= 0.5
	if pawn.combat.is_wounded():
		speed *= 0.7
	if not WorldGrid.is_indoors(pawn.cell):
		speed *= WeatherDirector.outdoor_work_mult()  # storms slow outdoor work
	work_progress += speed
	while work_progress >= 1.0:
		work_progress -= 1.0
		job.work_ticks -= 1

func _release_dest() -> void:
	if reserved_dest != WorldGrid.INVALID_CELL:
		WorldGrid.release_storage(reserved_dest)
		reserved_dest = WorldGrid.INVALID_CELL
