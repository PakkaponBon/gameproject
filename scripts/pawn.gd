class_name Pawn
extends Node2D

signal stats_changed
signal died

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0
const EAT_TICKS := 10
const WANDER_EVERY_TICKS := 3
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var cell: Vector2i
var target_cell: Vector2i
var job: Job = null
var carrying: WoodItem = null
var reserved_dest := WorldGrid.INVALID_CELL  # claimed stockpile cell while hauling
var food_target: FoodItem = null
var eat_ticks_left := 0
var dead := false
var wander_cooldown := 0

## 1 = preferred, higher = later, 0 = never does this job type.
var work_priorities := {Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1}

@onready var body: ColorRect = $Body
@onready var selection_ring: ColorRect = $SelectionRing
@onready var needs: PawnNeeds = $Needs
@onready var combat: PawnCombat = $Combat

func _ready() -> void:
	add_to_group("pawns")
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	needs.starved.connect(_die)
	needs.changed.connect(stats_changed.emit)
	needs.break_started.connect(_on_break_started)
	combat.damaged.connect(_on_damaged)
	combat.defeated.connect(_die)
	GameClock.ticked.connect(_on_tick)

func set_selected(on: bool) -> void:
	selection_ring.visible = on

func cycle_priority(type: Job.Type) -> void:
	# 1 -> 2 -> 3 -> 0 (off) -> 1
	work_priorities[type] = (int(work_priorities[type]) + 1) % 4

## Player command: overrides current work. A held job returns to the pool;
## carried wood is dropped on the spot.
func move_to(destination: Vector2i) -> void:
	if dead or not WorldGrid.in_bounds(destination):
		return
	_abort_work()
	target_cell = destination

func take_damage(amount: float) -> void:
	if not dead:
		combat.take_damage(amount)

func _on_damaged() -> void:
	needs.attacked()
	stats_changed.emit()

func _on_tick() -> void:
	if dead:
		return
	needs.tick()
	if dead:
		return  # starved just now
	combat.tick()
	_seek_food_if_hungry()
	# Melee is survival: an adjacent raider preempts everything else.
	if combat.engage_adjacent():
		return
	if cell != target_cell:
		_step()
	elif food_target:
		_eat()
	elif needs.on_break:
		_wander()
	elif carrying:
		_deliver()
	elif job:
		_work()
	else:
		job = JobManager.request_job(cell, work_priorities)
		if job:
			target_cell = job.cell

func _seek_food_if_hungry() -> void:
	if not needs.is_hungry() or food_target != null:
		return
	var food := _find_food()
	if food:
		_abort_work()
		food.reserved = true
		food_target = food
		eat_ticks_left = EAT_TICKS
		target_cell = food.cell

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
		needs.eat()

func _wander() -> void:
	wander_cooldown -= 1
	if wander_cooldown > 0:
		return
	wander_cooldown = WANDER_EVERY_TICKS
	var next: Vector2i = cell + DIRS.pick_random()
	if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
		cell = next
		target_cell = next

func _work() -> void:
	match job.type:
		Job.Type.HAUL:
			_start_carry(job.target as WoodItem)
		Job.Type.CHOP, Job.Type.BUILD:
			if not is_instance_valid(job.target):  # e.g. blueprint canceled
				job = null
				return
			job.work_ticks -= 1
			if job.work_ticks <= 0:
				var work_cell := job.cell
				var was_build := job.type == Job.Type.BUILD
				JobManager.complete_job(job)
				job = null
				if was_build:
					_step_off_wall(work_cell)

func _start_carry(wood: WoodItem) -> void:
	wood.pick_up(self)  # removes its haul job from the pool
	job = null
	var dest := WorldGrid.get_free_stockpile_cell(cell)
	if dest == WorldGrid.INVALID_CELL:
		wood.drop_at(cell)  # storage vanished since we took the job
		return
	WorldGrid.reserve_storage(dest)
	reserved_dest = dest
	carrying = wood
	target_cell = dest

func _deliver() -> void:
	_release_dest()
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
		WorldGrid.reserve_storage(dest)
		reserved_dest = dest
		target_cell = dest

func _step_off_wall(wall_cell: Vector2i) -> void:
	if not WorldGrid.is_wall(cell):
		return
	for dir in DIRS:
		var next := wall_cell + dir
		if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
			cell = next
			target_cell = next
			return

func _find_food() -> FoodItem:
	var best: FoodItem = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.reserved:
			continue
		var dist := float((food.cell - cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(cell, food.cell).is_empty():
			best = food
			best_dist = dist
	return best

func _release_dest() -> void:
	if reserved_dest != WorldGrid.INVALID_CELL:
		WorldGrid.release_storage(reserved_dest)
		reserved_dest = WorldGrid.INVALID_CELL

func _on_break_started() -> void:
	# Mental break: drop colony work, but keep heading to food if hungry.
	_abort_work(false)
	if food_target == null:
		target_cell = cell

func _abort_work(clear_food := true) -> void:
	if job:
		JobManager.release_job(job)
		job = null
	if carrying:
		carrying.drop_at(cell)
		carrying = null
	_release_dest()
	if clear_food:
		if is_instance_valid(food_target):
			food_target.reserved = false
		food_target = null

func _die() -> void:
	dead = true
	_abort_work()
	target_cell = cell
	body.color = Color(0.35, 0.35, 0.38)
	body.pivot_offset = body.size / 2.0
	body.rotation_degrees = 90.0
	stats_changed.emit()
	died.emit()

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
