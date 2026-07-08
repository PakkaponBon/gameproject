class_name Blueprint
extends Node2D
## A planned wall. Registers a build job on spawn; emits `built` when a
## pawn finishes constructing it. Walkable until built.

signal built(cell: Vector2i)

const BUILD_TICKS := 20  # 2 seconds at 10 ticks/sec

var cell: Vector2i
var job: Job

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	job = Job.new()
	job.type = Job.Type.BUILD
	job.target = self
	job.cell = cell
	job.work_ticks = BUILD_TICKS
	job.completed.connect(_on_built)
	JobManager.add_job(job)

func cancel() -> void:
	JobManager.remove_job(job)
	queue_free()

func _on_built() -> void:
	built.emit(cell)
	queue_free()
