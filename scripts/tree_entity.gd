class_name TreeEntity
extends Node2D
## A choppable tree. Registers its own chop job on spawn; when the job
## completes it drops a wood item and removes itself.
## (Named TreeEntity because `Tree` is a built-in Godot Control class.)

const CHOP_TICKS := 30  # 3 seconds at 10 ticks/sec
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")

var cell: Vector2i
var job: Job

func _ready() -> void:
	add_to_group("trees")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	job = Job.new()
	job.type = Job.Type.CHOP
	job.target = self
	job.cell = cell
	job.work_ticks = CHOP_TICKS
	job.completed.connect(_on_chopped)
	JobManager.add_job(job)

func _on_chopped() -> void:
	var wood: ResourceItem = RESOURCE_SCENE.instantiate()
	wood.resource_id = "wood"
	wood.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(wood)
	queue_free()
