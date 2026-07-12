class_name BerryBush
extends Node2D
## Wild food source: bears one food item, regrows a while after picking.
## The renewable floor under farming — forage can dip but never runs dry
## (Balance.START_FOOD bushes, Balance.BERRY_REGROW_DAYS regrowth).

const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const CHECK_EVERY := 30  # scan the food group ~3x/sec, not every tick

var cell: Vector2i
var start_with_berries := false  # new game: true; on load food is restored separately
var regrow_ticks := 0  # counts down only while the bush is bare

var _bare := false
var _check := 0

func _ready() -> void:
	add_to_group("bushes")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	regrow_ticks = _full_regrow()
	GameClock.ticked.connect(_on_tick)
	if start_with_berries:
		_grow_berries()

func _on_tick() -> void:
	_check -= 1
	if _check <= 0:
		_check = CHECK_EVERY
		_bare = not _has_food_here()
	if not _bare:
		return
	regrow_ticks -= 1
	if regrow_ticks <= 0:
		_grow_berries()
		_bare = false

func _grow_berries() -> void:
	var food: FoodItem = FOOD_SCENE.instantiate()
	food.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(food)
	regrow_ticks = _full_regrow()

func _has_food_here() -> bool:
	for node in get_tree().get_nodes_in_group("food"):
		if node is FoodItem and (node as FoodItem).cell == cell \
				and not (node.get_parent() is Pawn):
			return true
	return false

func _full_regrow() -> int:
	return int(Balance.BERRY_REGROW_DAYS * GameClock.TICKS_PER_DAY)
