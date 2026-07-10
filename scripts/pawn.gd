class_name Pawn
extends Node2D
## Movement, tick orchestration, and player-facing state for one villager.
## Behaviors live in components: PawnNeeds (stats), PawnSurvival (food and
## sleep), PawnWork (colony jobs), PawnCombat (melee).

signal stats_changed
signal died

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0
const WANDER_EVERY_TICKS := 3
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const BODY_COLOR := Color(0.231373, 0.482353, 0.831373)
const SLEEP_COLOR := Color(0.14, 0.29, 0.5)
const COLLAPSE_COLOR := Color(0.55, 0.65, 0.85)
const COLLAPSE_HP_DRAIN := 0.2  # per tick: ~50s from full HP to death

var cell: Vector2i
var target_cell: Vector2i
var collapsed := false  # starved: prone, helpless, bleeding out
var feed_job: Job = null
var dead := false
var wander_cooldown := 0

## 1 = preferred, higher = later, 0 = never does this job type.
var work_priorities := {Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1}

@onready var body: ColorRect = $Body
@onready var selection_ring: ColorRect = $SelectionRing
@onready var needs: PawnNeeds = $Needs
@onready var combat: PawnCombat = $Combat
@onready var work: PawnWork = $Work
@onready var survival: PawnSurvival = $Survival

func _ready() -> void:
	add_to_group("pawns")
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	needs.starved.connect(_collapse)
	needs.changed.connect(stats_changed.emit)
	needs.break_started.connect(_on_break_started)
	combat.damaged.connect(_on_damaged)
	combat.defeated.connect(_die)
	GameClock.ticked.connect(_on_tick)

func set_selected(on: bool) -> void:
	selection_ring.visible = on

func set_sleep_visual(on: bool) -> void:
	if not dead:
		body.color = SLEEP_COLOR if on else BODY_COLOR

func cycle_priority(type: Job.Type) -> void:
	# 1 -> 2 -> 3 -> 0 (off) -> 1
	work_priorities[type] = (int(work_priorities[type]) + 1) % 4

## Player command: overrides current work; carried wood drops on the spot.
func move_to(destination: Vector2i) -> void:
	if dead or collapsed or not WorldGrid.in_bounds(destination):
		return
	survival.wake()
	_abort_all()
	target_cell = destination

func take_damage(amount: float) -> void:
	if not dead:
		combat.take_damage(amount)

## Fed by a rescuer: back on your feet, hungry but alive.
func be_fed() -> void:
	collapsed = false
	feed_job = null
	needs.hunger = 50.0
	body.rotation_degrees = 0.0
	body.color = BODY_COLOR
	stats_changed.emit()

## Save/load: restore a corpse without re-running death side effects.
func restore_dead() -> void:
	dead = true
	_apply_death_visuals()

## Save/load: restore a collapsed pawn (re-registers its FEED job).
func restore_collapse() -> void:
	collapsed = true
	_apply_collapse_visuals()
	_register_feed_job()

## After finishing a build, don't stand inside the new wall.
func step_off_wall(wall_cell: Vector2i) -> void:
	if not WorldGrid.is_wall(cell):
		return
	for dir in DIRS:
		var next := wall_cell + dir
		if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
			cell = next
			target_cell = next
			return

func _on_tick() -> void:
	if dead:
		return
	needs.tick(survival.sleeping, survival.is_in_bed())
	if dead:
		return
	if collapsed:
		combat.drain(COLLAPSE_HP_DRAIN)  # defeated -> _die
		return
	combat.tick()
	# Melee is survival: an adjacent raider preempts (and wakes) everything.
	if combat.engage_adjacent():
		survival.wake()
		return
	if survival.sleeping:
		if needs.is_rested() or needs.is_hungry():
			survival.wake()
		return
	survival.seek_food()
	survival.seek_bed()
	if cell != target_cell:
		_step()
	elif survival.food_target:
		survival.eat_tick()
	elif survival.at_bed():
		survival.fall_asleep()
	elif needs.wants_sleep() and needs.is_exhausted():
		survival.fall_asleep()  # no bed available: collapse where we stand
	elif needs.on_break:
		_wander()
	elif work.busy():
		work.on_arrived()
	else:
		work.request_next()

func _step() -> void:
	# Repath every tick so walls placed mid-walk are respected immediately.
	# allow_partial_path lets a click on a wall walk to the closest reachable cell.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target_cell, true)
	if path.size() < 2:
		# Destination unreachable; give up. Job/food searches filter
		# unreachable targets, so abandoned work won't be re-taken.
		target_cell = cell
		_abort_all()
		return
	cell = path[1]

func _wander() -> void:
	wander_cooldown -= 1
	if wander_cooldown > 0:
		return
	wander_cooldown = WANDER_EVERY_TICKS
	var next: Vector2i = cell + DIRS.pick_random()
	if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
		cell = next
		target_cell = next

func _on_damaged() -> void:
	if survival.sleeping:
		survival.wake()
	needs.attacked()
	stats_changed.emit()

func _on_break_started() -> void:
	# Mental break: drop colony work, but keep heading to food if hungry.
	work.abort()
	if survival.food_target == null:
		target_cell = cell

func _abort_all(clear_food := true) -> void:
	work.abort()
	survival.release_claims(clear_food)

func _collapse() -> void:
	if collapsed or dead:
		return
	survival.wake()
	_abort_all()
	collapsed = true
	target_cell = cell
	_apply_collapse_visuals()
	_register_feed_job()
	stats_changed.emit()

func _register_feed_job() -> void:
	feed_job = Job.new()
	feed_job.type = Job.Type.FEED
	feed_job.cell = cell
	feed_job.target = self
	feed_job.completed.connect(be_fed)
	JobManager.add_job(feed_job)

func _apply_collapse_visuals() -> void:
	body.color = COLLAPSE_COLOR
	body.pivot_offset = body.size / 2.0
	body.rotation_degrees = 90.0

func _die() -> void:
	dead = true
	collapsed = false
	if feed_job:
		JobManager.remove_job(feed_job)
		feed_job = null
	_abort_all()
	target_cell = cell
	_apply_death_visuals()
	stats_changed.emit()
	died.emit()

func _apply_death_visuals() -> void:
	body.color = Color(0.35, 0.35, 0.38)
	body.pivot_offset = body.size / 2.0
	body.rotation_degrees = 90.0

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
