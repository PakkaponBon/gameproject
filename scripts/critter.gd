class_name Critter
extends Node2D
## Ambient life (rabbit, bird): wanders, flees nothing. Huntable critters
## (rabbits) also carry a HUNT job — a villager runs one down for meat.
## Birds stay pure set dressing. Life first, food second.

const MOVE_EVERY_TICKS := 4
const FOOD_SCENE := preload("res://scenes/food_item.tscn")

var cell: Vector2i
var move_cooldown := 0
var huntable := false  # set before add_child
var hunt_job: Job = null

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	if huntable:
		add_to_group("game")
		hunt_job = Job.new()
		hunt_job.type = Job.Type.HUNT
		hunt_job.cell = cell
		hunt_job.target = self
		hunt_job.work_ticks = 12  # a short scuffle once cornered
		JobManager.add_job(hunt_job)
	GameClock.ticked.connect(_on_tick)

## Caught: drop meat (raw food) with a dust puff — no gore, per tone rule.
func hunted() -> void:
	if hunt_job:
		JobManager.remove_job(hunt_job)
		hunt_job = null
	for i in Balance.MEAT_PER_KILL:
		var meat: FoodItem = FOOD_SCENE.instantiate()
		var spot := cell + Pawn.DIRS[i % Pawn.DIRS.size()] if i > 0 else cell
		if not WorldGrid.in_bounds(spot) or WorldGrid.is_wall(spot):
			spot = cell
		meat.position = WorldGrid.cell_to_world(spot)
		get_parent().add_child(meat)
	Fx.burst(get_parent(), position, Color(0.72, 0.55, 0.42))
	queue_free()

func _on_tick() -> void:
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS + randi_range(0, 12)
	var next: Vector2i = cell + Pawn.DIRS.pick_random()
	if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
		cell = next
		if hunt_job:
			hunt_job.cell = cell  # keep the job's distance/reachability current

func _process(delta: float) -> void:
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, 6.0 * delta))
	if absf(dest.x - position.x) > 0.5:
		($Body as Sprite2D).flip_h = dest.x < position.x
