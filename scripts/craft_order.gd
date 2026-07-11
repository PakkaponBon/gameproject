class_name CraftOrder
extends Node2D
## One in-progress recipe at a workstation: SUPPLY jobs bring the inputs,
## then a timed CRAFT job produces the output beside the station.
## ForgeKeeper spawns and tracks these.

const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const SPILL: Array[Vector2i] = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var recipe_id := "smelt_iron"  # set before add_child
var cell: Vector2i
var required := {}
var delivered := {}
var supply_jobs: Array[Job] = []
var craft_job: Job = null

@onready var body: ColorRect = $Body

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	required = RecipeDefs.get_def(recipe_id).inputs.duplicate()
	_register_supply_jobs()
	_update_visual()

func cancel() -> void:
	for job in supply_jobs:
		JobManager.remove_job(job)
	if craft_job:
		JobManager.remove_job(craft_job)
	# Refund delivered inputs as loose items.
	for id: String in delivered:
		for i in int(delivered[id]):
			_spawn_item(id, cell)
	queue_free()

## Save/load: rebuild job state from saved progress.
func restore(delivered_counts: Dictionary, craft_work: int) -> void:
	for job in supply_jobs:
		JobManager.remove_job(job)
	supply_jobs.clear()
	if craft_job:
		JobManager.remove_job(craft_job)
		craft_job = null
	delivered = delivered_counts
	if _fully_supplied():
		_register_craft_job()
		if craft_work >= 0:
			craft_job.work_ticks = craft_work
	else:
		_register_supply_jobs()
	_update_visual()

func _fully_supplied() -> bool:
	for id: String in required:
		if int(delivered.get(id, 0)) < int(required[id]):
			return false
	return true

func _register_supply_jobs() -> void:
	for id: String in required:
		for i in int(required[id]) - int(delivered.get(id, 0)):
			var job := Job.new()
			job.type = Job.Type.SUPPLY
			job.resource_id = id
			job.cell = cell
			job.target = self
			job.completed.connect(_on_input_delivered.bind(id))
			JobManager.add_job(job)
			supply_jobs.append(job)

func _on_input_delivered(id: String) -> void:
	delivered[id] = int(delivered.get(id, 0)) + 1
	_update_visual()
	if _fully_supplied():
		_register_craft_job()

func _register_craft_job() -> void:
	craft_job = Job.new()
	craft_job.type = Job.Type.CRAFT
	craft_job.cell = cell
	craft_job.target = self
	craft_job.work_ticks = int(RecipeDefs.get_def(recipe_id).craft_ticks)
	craft_job.completed.connect(_on_crafted)
	JobManager.add_job(craft_job)

func _on_crafted() -> void:
	var def := RecipeDefs.get_def(recipe_id)
	var output: String = def.output
	var remaining := int(def.get("output_count", 1))
	for offset in SPILL:
		if remaining <= 0:
			break
		var spot := cell + offset
		if offset != Vector2i.ZERO and WorldGrid.in_bounds(spot) \
				and not WorldGrid.is_wall(spot) and not WorldGrid.items.has(spot):
			_spawn_item(output, spot)
			remaining -= 1
	while remaining > 0:  # fallback: on the station itself
		_spawn_item(output, cell)
		remaining -= 1
	queue_free()

func _spawn_item(id: String, spot: Vector2i) -> void:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = id
	item.position = WorldGrid.cell_to_world(spot)
	get_parent().add_child(item)

func _update_visual() -> void:
	var total_required := 0
	var total_delivered := 0
	for id: String in required:
		total_required += int(required[id])
		total_delivered += int(delivered.get(id, 0))
	var ratio := 1.0 if total_required == 0 else float(total_delivered) / float(total_required)
	body.color.a = 0.25 + 0.3 * ratio
