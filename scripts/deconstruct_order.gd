class_name DeconstructOrder
extends Node2D
## An order to tear down a built structure. Registers a DECONSTRUCT job
## (worked from an adjacent cell); EventBus.building_deconstructed fires
## when a pawn finishes it. Main owns removal and the refund drop.

var cell: Vector2i
var job: Job

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var id: String = WorldGrid.buildings[cell]
	job = Job.new()
	job.type = Job.Type.DECONSTRUCT
	job.cell = cell
	job.target = self
	# Tearing down takes half the build time.
	job.work_ticks = maxi(1, int(BuildingDefs.get_def(id).build_ticks) / 2)
	job.completed.connect(_on_done)
	JobManager.add_job(job)

func cancel() -> void:
	JobManager.remove_job(job)
	queue_free()

## Save/load: restore remaining work.
func restore(work: int) -> void:
	job.work_ticks = work

func _on_done() -> void:
	EventBus.building_deconstructed.emit(cell)
	queue_free()
