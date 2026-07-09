class_name Crop
extends Node2D
## One planted crop of any kind (data-driven via CropDefs). Grows on the
## tick, registers a HARVEST job at maturity, drops food when harvested.
## Winter kills it via kill().

const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const SPILL: Array[Vector2i] = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const HARVEST_TICKS := 15
const SPROUT_SIZE := 3.0
const MATURE_SIZE := 12.0

var crop_id := "potato"  # set before add_child
var cell: Vector2i
var growth_ticks := 0
var grow_ticks_total := 1
var harvest_job: Job = null

@onready var body: ColorRect = $Body

func _ready() -> void:
	add_to_group("crops")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var def := CropDefs.get_def(crop_id)
	grow_ticks_total = maxi(1, int(float(def.grow_days) * GameClock.TICKS_PER_DAY))
	body.color = def.color
	_update_visual()
	GameClock.ticked.connect(_on_tick)

func is_mature() -> bool:
	return growth_ticks >= grow_ticks_total

## Winter frost: no harvest, no refund.
func kill() -> void:
	if harvest_job:
		JobManager.remove_job(harvest_job)
	queue_free()

## Save/load: resume growth (and maturity) without replaying ticks.
func restore(ticks: int) -> void:
	growth_ticks = ticks
	_update_visual()
	if is_mature():
		_register_harvest_job()

func _on_tick() -> void:
	if is_mature():
		return
	growth_ticks += 1
	if growth_ticks % 10 == 0 or is_mature():  # throttle visual updates
		_update_visual()
	if is_mature():
		_register_harvest_job()

func _register_harvest_job() -> void:
	harvest_job = Job.new()
	harvest_job.type = Job.Type.HARVEST
	harvest_job.cell = cell
	harvest_job.target = self
	harvest_job.work_ticks = HARVEST_TICKS
	harvest_job.completed.connect(_on_harvested)
	JobManager.add_job(harvest_job)

func _on_harvested() -> void:
	var to_drop := int(CropDefs.get_def(crop_id).yield)
	var dropped := 0
	for offset in SPILL:
		if dropped >= to_drop:
			break
		var spot := cell + offset
		if WorldGrid.in_bounds(spot) and not WorldGrid.is_wall(spot):
			_spawn_food(spot)
			dropped += 1
	while dropped < to_drop:  # fallback: stack on the field cell
		_spawn_food(cell)
		dropped += 1
	EventBus.crop_harvested.emit(cell)
	queue_free()

func _spawn_food(spot: Vector2i) -> void:
	var food: Node2D = FOOD_SCENE.instantiate()
	food.position = WorldGrid.cell_to_world(spot)
	get_parent().add_child(food)

func _update_visual() -> void:
	var t := minf(float(growth_ticks) / float(grow_ticks_total), 1.0)
	var s := lerpf(SPROUT_SIZE, MATURE_SIZE, t)
	body.offset_left = -s / 2.0
	body.offset_top = -s / 2.0
	body.offset_right = s / 2.0
	body.offset_bottom = s / 2.0
