class_name Pawn
extends Node2D

signal hunger_changed(value: float)
signal died

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0

const HUNGER_MAX := 100.0
const HUNGER_DRAIN_PER_TICK := 0.1  # empty in ~100s at 10 ticks/sec
const SEEK_FOOD_THRESHOLD := 35.0
const EAT_TICKS := 10

var cell: Vector2i
var target_cell: Vector2i
var job: Job = null
var carrying: WoodItem = null
var hunger := HUNGER_MAX
var food_target: FoodItem = null
var eat_ticks_left := 0
var dead := false

@onready var body: ColorRect = $Body

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

## Player command: overrides current work. A held job returns to the pool;
## carried wood is dropped on the spot.
func move_to(destination: Vector2i) -> void:
	if dead or not WorldGrid.in_bounds(destination):
		return
	_abort_work()
	target_cell = destination

func _on_tick() -> void:
	if dead:
		return
	_tick_hunger()
	if dead:
		return
	if cell != target_cell:
		_step()
	elif food_target:
		_eat()
	elif carrying:
		_deliver()
	elif job:
		_work()
	else:
		_find_something_to_do()

func _tick_hunger() -> void:
	hunger = maxf(hunger - HUNGER_DRAIN_PER_TICK, 0.0)
	hunger_changed.emit(hunger)
	if hunger <= 0.0:
		_die()
		return
	# Hunger overrides work: below the threshold, drop everything and
	# head for the nearest reachable food (if any exists).
	if hunger < SEEK_FOOD_THRESHOLD and food_target == null:
		var food := _find_food()
		if food:
			_abort_work()
			food_target = food
			eat_ticks_left = EAT_TICKS
			target_cell = food.cell

func _find_something_to_do() -> void:
	job = JobManager.request_job(cell)
	if job:
		target_cell = job.cell

func _step() -> void:
	# Repath every tick so walls placed mid-walk are respected immediately.
	# allow_partial_path lets a click on a wall walk to the closest reachable cell.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target_cell, true)
	if path.size() < 2:
		# Destination unreachable; give up. Job/food searches filter
		# unreachable targets, so abandoned work won't be re-taken.
		target_cell = cell
		_abort_work()
		return
	cell = path[1]

func _eat() -> void:
	if not is_instance_valid(food_target):
		food_target = null
		return
	eat_ticks_left -= 1
	if eat_ticks_left <= 0:
		food_target.queue_free()
		food_target = null
		hunger = HUNGER_MAX
		hunger_changed.emit(hunger)

func _work() -> void:
	match job.type:
		Job.Type.CHOP:
			job.work_ticks -= 1
			if job.work_ticks <= 0:
				JobManager.complete_job(job)
				job = null
		Job.Type.HAUL:
			_pick_up(job.target as WoodItem)

func _pick_up(wood: WoodItem) -> void:
	wood.pick_up(self)  # removes its haul job from the pool
	job = null
	var dest := WorldGrid.get_free_stockpile_cell(cell)
	if dest == WorldGrid.INVALID_CELL:
		wood.drop_at(cell)  # storage vanished since we took the job
		return
	carrying = wood
	target_cell = dest

func _deliver() -> void:
	if WorldGrid.is_cell_free_for_storage(cell):
		carrying.drop_at(cell)
		carrying = null
		return
	# Destination was filled or unzoned mid-carry; try another cell.
	var dest := WorldGrid.get_free_stockpile_cell(cell)
	if dest == WorldGrid.INVALID_CELL:
		carrying.drop_at(cell)
		carrying = null
	else:
		target_cell = dest

func _find_food() -> FoodItem:
	var best: FoodItem = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		var dist := float((food.cell - cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(cell, food.cell).is_empty():
			best = food
			best_dist = dist
	return best

func _abort_work() -> void:
	if job:
		JobManager.release_job(job)
		job = null
	if carrying:
		carrying.drop_at(cell)
		carrying = null
	food_target = null

func _die() -> void:
	dead = true
	_abort_work()
	target_cell = cell
	body.color = Color(0.35, 0.35, 0.38)
	body.pivot_offset = body.size / 2.0
	body.rotation_degrees = 90.0
	died.emit()

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
