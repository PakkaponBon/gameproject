class_name PawnSurvival
extends Node
## Need-driven behaviors for one pawn: finding food and eating, claiming
## beds and sleeping. Stats live in PawnNeeds; movement on the pawn.

const EAT_TICKS := 10
const WANDER_EVERY_TICKS := 3

var food_target: FoodItem = null
var eat_ticks_left := 0
var sleeping := false
var bed_cell := WorldGrid.INVALID_CELL  # claimed bed (or target while walking)
var wander_cooldown := 0

@onready var pawn: Pawn = get_parent()

func is_in_bed() -> bool:
	return sleeping and pawn.cell == bed_cell

func at_bed() -> bool:
	return bed_cell != WorldGrid.INVALID_CELL and pawn.cell == bed_cell

## Hunger overrides work: below the threshold, drop everything and head
## for the nearest reachable unclaimed food (if any exists).
func seek_food() -> void:
	if not pawn.needs.is_hungry() or food_target != null:
		return
	var food := _find_food()
	if food == null:
		return
	pawn.work.abort()
	bed_cell = WorldGrid.INVALID_CELL
	food.reserved = true
	food_target = food
	eat_ticks_left = EAT_TICKS
	pawn.target_cell = food.cell

func seek_bed() -> void:
	if bed_cell != WorldGrid.INVALID_CELL or food_target:
		return
	# Sleep for rest — or for bed rest when badly hurt.
	if not (pawn.needs.wants_sleep() or pawn.combat.is_wounded()):
		return
	var bed := _find_free_bed()
	if bed != WorldGrid.INVALID_CELL:
		pawn.work.abort()
		bed_cell = bed
		pawn.target_cell = bed

func eat_tick() -> void:
	if not is_instance_valid(food_target):
		food_target = null
		return
	eat_ticks_left -= 1
	if eat_ticks_left <= 0:
		var was_meal := food_target.meal
		food_target.queue_free()
		food_target = null
		EventBus.play_sfx.emit("eat")
		pawn.needs.eat(was_meal)

## Mental-break behavior: aimless steps.
func wander() -> void:
	wander_cooldown -= 1
	if wander_cooldown > 0:
		return
	wander_cooldown = WANDER_EVERY_TICKS
	var next: Vector2i = pawn.cell + Pawn.DIRS.pick_random()
	if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
		pawn.cell = next
		pawn.target_cell = next

func fall_asleep() -> void:
	sleeping = true
	pawn.set_sleep_visual(true)

func wake() -> void:
	sleeping = false
	bed_cell = WorldGrid.INVALID_CELL
	pawn.set_sleep_visual(false)

## Save/load: resume sleeping without re-running the fall-asleep search.
func restore_sleep() -> void:
	fall_asleep()

func release_claims(clear_food := true) -> void:
	bed_cell = WorldGrid.INVALID_CELL
	if clear_food:
		if is_instance_valid(food_target):
			food_target.reserved = false
		food_target = null

func _find_food() -> FoodItem:
	var best: FoodItem = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.reserved:
			continue
		var dist := float((food.cell - pawn.cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(pawn.cell, food.cell).is_empty():
			best = food
			best_dist = dist
	return best

func _find_free_bed() -> Vector2i:
	var best := WorldGrid.INVALID_CELL
	var best_dist := INF
	for spot: Vector2i in WorldGrid.buildings:
		var def: Dictionary = BuildingDefs.get_def(WorldGrid.buildings[spot])
		if not def.get("sleep_spot", false) or _bed_claimed(spot):
			continue
		var dist := float((spot - pawn.cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(pawn.cell, spot).is_empty():
			best = spot
			best_dist = dist
	return best

func _bed_claimed(bed: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("pawns"):
		var other := node as Pawn
		if other != pawn and other.survival.bed_cell == bed:
			return true
	return false
