class_name WoodItem
extends Node2D
## A loose resource on the ground. Registers a haul job for itself whenever
## it sits outside a stockpile; stored wood (on a free stockpile cell) is inert.

var cell: Vector2i
var haul_job: Job = null
var reserved := false  # claimed as blueprint material by a supplier pawn

var _home: Node = null  # container to return to after being carried

func _ready() -> void:
	add_to_group("wood")
	_home = get_parent()
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	_settle()

func pick_up(carrier: Node2D) -> void:
	WorldGrid.unregister_item(cell)
	if haul_job:
		JobManager.remove_job(haul_job)
		haul_job = null
	reparent(carrier)
	position = Vector2(0, -10)

func drop_at(drop_cell: Vector2i) -> void:
	reserved = false
	reparent(_home)
	cell = drop_cell
	position = WorldGrid.cell_to_world(cell)
	_settle()

func _settle() -> void:
	# Check storage BEFORE registering, or our own presence marks the cell taken.
	var stored := WorldGrid.is_cell_free_for_storage(cell)
	WorldGrid.register_item(cell, self)
	if not stored:
		_register_haul_job()

func _register_haul_job() -> void:
	haul_job = Job.new()
	haul_job.type = Job.Type.HAUL
	haul_job.cell = cell
	haul_job.target = self
	JobManager.add_job(haul_job)
