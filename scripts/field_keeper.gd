class_name FieldKeeper
extends Node
## Maintains PLANT jobs for empty field cells (outside winter), spawns
## crops when planting completes, and kills standing crops at the frost.
## Scene-local to Main, like RaidDirector.

const CROP_SCENE := preload("res://scenes/crop.tscn")
const PLANT_TICKS := 15
const WINTER_INDEX := 3
const SPRING_INDEX := 0

var plant_jobs := {}  # cell -> Job
var spawn_parent: Node2D = null  # assigned by Main

func _ready() -> void:
	GameClock.season_changed.connect(_on_season_changed)
	EventBus.crop_harvested.connect(ensure_plant_job)

func is_winter() -> bool:
	return GameClock.season_index() == WINTER_INDEX

## Called when a field cell is painted or becomes empty again.
func ensure_plant_job(cell: Vector2i) -> void:
	if is_winter() or plant_jobs.has(cell) or not WorldGrid.fields.has(cell):
		return
	if _crop_at(cell):
		return
	var job := Job.new()
	job.type = Job.Type.PLANT
	job.cell = cell
	job.target = self
	job.work_ticks = PLANT_TICKS
	job.completed.connect(_on_planted.bind(cell))
	JobManager.add_job(job)
	plant_jobs[cell] = job

func remove_plant_job(cell: Vector2i) -> void:
	if plant_jobs.has(cell):
		JobManager.remove_job(plant_jobs[cell])
		plant_jobs.erase(cell)

func spawn_crop(cell: Vector2i, crop_id: String) -> Crop:
	var crop: Crop = CROP_SCENE.instantiate()
	crop.crop_id = crop_id
	crop.position = WorldGrid.cell_to_world(cell)
	spawn_parent.add_child(crop)
	return crop

## Re-derive plant jobs from field state (after load, and each spring).
func sync_all() -> void:
	for cell: Vector2i in WorldGrid.fields:
		ensure_plant_job(cell)

func _on_planted(cell: Vector2i) -> void:
	plant_jobs.erase(cell)
	if WorldGrid.fields.has(cell):  # not unzoned mid-plant
		spawn_crop(cell, WorldGrid.fields[cell])

func _on_season_changed(season: int) -> void:
	if season == WINTER_INDEX:
		for node in get_tree().get_nodes_in_group("crops"):
			(node as Crop).kill()
		for cell: Vector2i in plant_jobs.keys():
			remove_plant_job(cell)
	elif season == SPRING_INDEX:
		sync_all()

func _crop_at(cell: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("crops"):
		if (node as Crop).cell == cell:
			return true
	return false
