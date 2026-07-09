class_name Pawn
extends Node2D

signal stats_changed
signal died

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0
const EAT_TICKS := 10
const WANDER_EVERY_TICKS := 3
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const BODY_COLOR := Color(0.231373, 0.482353, 0.831373)
const SLEEP_COLOR := Color(0.14, 0.29, 0.5)

var cell: Vector2i
var target_cell: Vector2i
var food_target: FoodItem = null
var eat_ticks_left := 0
var sleeping := false
var bed_cell := WorldGrid.INVALID_CELL  # claimed bed (or target while walking)
var dead := false
var wander_cooldown := 0

## 1 = preferred, higher = later, 0 = never does this job type.
var work_priorities := {Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1}

@onready var body: ColorRect = $Body
@onready var selection_ring: ColorRect = $SelectionRing
@onready var needs: PawnNeeds = $Needs
@onready var combat: PawnCombat = $Combat
@onready var work: PawnWork = $Work

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

## Player command: overrides current work; carried wood drops on the spot.
func move_to(destination: Vector2i) -> void:
	if dead or not WorldGrid.in_bounds(destination):
		return
	_wake()
	_abort_all()
	target_cell = destination

func take_damage(amount: float) -> void:
	if not dead:
		combat.take_damage(amount)

## Save/load: restore a corpse without re-running death side effects.
func restore_dead() -> void:
	dead = true
	_apply_death_visuals()

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
	needs.tick(sleeping, sleeping and cell == bed_cell)
	if dead:
		return  # starved just now
	combat.tick()
	# Melee is survival: an adjacent raider preempts (and wakes) everything.
	if combat.engage_adjacent():
		_wake()
		return
	if sleeping:
		if needs.is_rested() or needs.is_hungry():
			_wake()
		return
	_seek_food_if_hungry()
	_seek_bed_if_tired()
	if cell != target_cell:
		_step()
	elif food_target:
		_eat()
	elif bed_cell != WorldGrid.INVALID_CELL and cell == bed_cell:
		_fall_asleep()
	elif needs.wants_sleep() and needs.is_exhausted():
		_fall_asleep()  # no bed available: collapse where we stand
	elif needs.on_break:
		_wander()
	elif work.busy():
		work.on_arrived()
	else:
		work.request_next()

func _seek_food_if_hungry() -> void:
	if not needs.is_hungry() or food_target != null:
		return
	var food := _find_food()
	if food:
		_abort_all()
		food.reserved = true
		food_target = food
		eat_ticks_left = EAT_TICKS
		target_cell = food.cell

func _seek_bed_if_tired() -> void:
	if not needs.wants_sleep() or bed_cell != WorldGrid.INVALID_CELL or food_target:
		return
	var bed := _find_free_bed()
	if bed != WorldGrid.INVALID_CELL:
		work.abort()
		bed_cell = bed
		target_cell = bed

func _find_free_bed() -> Vector2i:
	var best := WorldGrid.INVALID_CELL
	var best_dist := INF
	for spot: Vector2i in WorldGrid.buildings:
		var def: Dictionary = BuildingDefs.get_def(WorldGrid.buildings[spot])
		if not def.get("sleep_spot", false) or _bed_claimed(spot):
			continue
		var dist := float((spot - cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(cell, spot).is_empty():
			best = spot
			best_dist = dist
	return best

func _bed_claimed(bed: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("pawns"):
		var other := node as Pawn
		if other != self and other.bed_cell == bed:
			return true
	return false

func _fall_asleep() -> void:
	sleeping = true
	body.color = SLEEP_COLOR

func _wake() -> void:
	sleeping = false
	bed_cell = WorldGrid.INVALID_CELL
	if not dead:
		body.color = BODY_COLOR

## Save/load: resume sleeping without re-running the fall-asleep search.
func restore_sleep() -> void:
	_fall_asleep()

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

func _on_damaged() -> void:
	if sleeping:
		_wake()
	needs.attacked()
	stats_changed.emit()

func _on_break_started() -> void:
	# Mental break: drop colony work, but keep heading to food if hungry.
	work.abort()
	if food_target == null:
		target_cell = cell

func _abort_all(clear_food := true) -> void:
	work.abort()
	bed_cell = WorldGrid.INVALID_CELL  # release any bed claim / walk
	if clear_food:
		if is_instance_valid(food_target):
			food_target.reserved = false
		food_target = null

func _die() -> void:
	dead = true
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
