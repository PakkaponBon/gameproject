class_name Pawn
extends Node2D

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0

var cell: Vector2i
var target_cell: Vector2i
var job: Job = null
var carrying: WoodItem = null

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

## Player command: overrides current work. A held job returns to the pool;
## carried wood is dropped on the spot.
func move_to(destination: Vector2i) -> void:
	if not WorldGrid.in_bounds(destination):
		return
	_abort_work()
	target_cell = destination

func _on_tick() -> void:
	if job == null and carrying == null and cell == target_cell:
		job = JobManager.request_job(cell)
		if job:
			target_cell = job.cell
	if cell != target_cell:
		_step()
	elif carrying:
		_deliver()
	elif job:
		_work()

func _step() -> void:
	# Repath every tick so walls placed mid-walk are respected immediately.
	# allow_partial_path lets a click on a wall walk to the closest reachable cell.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target_cell, true)
	if path.size() < 2:
		# Destination unreachable; give up. request_job filters unreachable
		# jobs, so abandoned work won't be immediately re-taken.
		target_cell = cell
		_abort_work()
		return
	cell = path[1]

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

func _abort_work() -> void:
	if job:
		JobManager.release_job(job)
		job = null
	if carrying:
		carrying.drop_at(cell)
		carrying = null

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
