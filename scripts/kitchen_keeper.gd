class_name KitchenKeeper
extends Node
## Keeps stoves cooking: while 2+ raw foods exist (and meals aren't
## overstocked), each stove offers a COOK job. Cooking consumes two raw
## foods from the colony's stores and produces one meal at the stove.

const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const COOK_TICKS := 30
const RAW_PER_MEAL := 2
const CHECK_EVERY_TICKS := 20

var cook_jobs := {}  # stove cell -> Job
var spawn_parent: Node2D = null  # assigned by Main
var _cooldown := 0

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	for cell: Vector2i in cook_jobs.keys():
		if not _is_kitchen(cell):
			JobManager.remove_job(cook_jobs[cell])
			cook_jobs.erase(cell)
	if not _worth_cooking():
		return
	for cell: Vector2i in WorldGrid.buildings:
		if _is_kitchen(cell) and not cook_jobs.has(cell):
			_offer_job(cell)

func _offer_job(cell: Vector2i) -> void:
	var job := Job.new()
	job.type = Job.Type.COOK
	job.cell = cell
	job.target = self
	job.work_ticks = COOK_TICKS
	job.completed.connect(_on_cooked.bind(cell))
	JobManager.add_job(job)
	cook_jobs[cell] = job

func _on_cooked(cell: Vector2i) -> void:
	cook_jobs.erase(cell)
	if not _consume_raw(RAW_PER_MEAL):
		return  # pantry emptied while cooking
	var food: FoodItem = FOOD_SCENE.instantiate()
	food.meal = true
	food.position = WorldGrid.cell_to_world(cell + Vector2i.DOWN)
	spawn_parent.add_child(food)

func _is_kitchen(cell: Vector2i) -> bool:
	if not WorldGrid.buildings.has(cell):
		return false
	return bool(BuildingDefs.get_def(WorldGrid.buildings[cell]).get("kitchen", false))

func _worth_cooking() -> bool:
	var raw := 0
	var meals := 0
	var pawns := get_tree().get_nodes_in_group("pawns").size()
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.reserved:
			continue
		if food.meal:
			meals += 1
		else:
			raw += 1
	return raw >= RAW_PER_MEAL and meals < pawns * 2

func _consume_raw(count: int) -> bool:
	var found: Array[FoodItem] = []
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if not food.meal and not food.reserved:
			found.append(food)
			if found.size() >= count:
				break
	if found.size() < count:
		return false
	for food in found:
		food.queue_free()
	return true
