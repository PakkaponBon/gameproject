class_name Blueprint
extends Node2D
## A planned building. Registers one SUPPLY job per missing material unit;
## once fully supplied it registers the timed BUILD job. Fires
## EventBus.building_built when finished. Walkable until built.

const WOOD_SCENE := preload("res://scenes/wood_item.tscn")

var building_id := "wall"
var cell: Vector2i
var required := 0
var delivered := 0
var supply_jobs: Array[Job] = []
var build_job: Job = null

@onready var body: ColorRect = $Body

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var def: Dictionary = BuildingDefs.get_def(building_id)
	body.color = def.ghost  # alpha applied by _update_visual
	required = int(def.cost.get("wood", 0))
	if delivered >= required:
		_register_build_job()
	else:
		_register_supply_jobs()
	_update_visual()

func cancel() -> void:
	for job in supply_jobs:
		JobManager.remove_job(job)
	if build_job:
		JobManager.remove_job(build_job)
	# Refund what was already delivered as loose wood on the site.
	for i in delivered:
		var wood: Node2D = WOOD_SCENE.instantiate()
		wood.position = WorldGrid.cell_to_world(cell)
		get_parent().add_child(wood)
	queue_free()

## Save/load: rebuild job state from saved progress.
func restore(delivered_count: int, build_work: int) -> void:
	for job in supply_jobs:
		JobManager.remove_job(job)
	supply_jobs.clear()
	if build_job:
		JobManager.remove_job(build_job)
		build_job = null
	delivered = delivered_count
	if delivered >= required:
		_register_build_job()
		if build_work >= 0:
			build_job.work_ticks = build_work
	else:
		_register_supply_jobs()
	_update_visual()

func _register_supply_jobs() -> void:
	for i in required - delivered:
		var job := Job.new()
		job.type = Job.Type.SUPPLY
		job.cell = cell
		job.target = self
		job.completed.connect(_on_material_delivered)
		JobManager.add_job(job)
		supply_jobs.append(job)

func _on_material_delivered() -> void:
	delivered += 1
	_update_visual()
	if delivered >= required:
		_register_build_job()

func _register_build_job() -> void:
	build_job = Job.new()
	build_job.type = Job.Type.BUILD
	build_job.cell = cell
	build_job.target = self
	build_job.work_ticks = int(BuildingDefs.get_def(building_id).build_ticks)
	build_job.completed.connect(_on_built)
	JobManager.add_job(build_job)

func _on_built() -> void:
	EventBus.building_built.emit(cell, building_id)
	queue_free()

func _update_visual() -> void:
	# Placeholder feedback: the ghost gets more opaque as materials arrive.
	var ratio := 1.0 if required == 0 else float(delivered) / float(required)
	body.color.a = 0.35 + 0.35 * ratio
