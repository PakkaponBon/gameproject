class_name Livestock
extends Node2D
## Farm animals (chickens for now; sheep arrive with the v1.3 cloth chain).
## Wander like critters but productive: lay an egg (raw food) on a timer.
## No breeding — you acquire them by building their home (the coop).

const MOVE_EVERY_TICKS := 6
const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const REGIONS := {"chicken": Rect2(384, 0, 16, 16)}  # reuse the bird sprite
const TINTS := {"chicken": Color(1.05, 1.0, 0.85)}   # cream hen

var cell: Vector2i
var kind := "chicken"  # set before add_child
var move_cooldown := 0
var lay_timer := 0  # ticks until the next egg (persisted)

func _ready() -> void:
	add_to_group("livestock")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var body: Sprite2D = $Body
	if REGIONS.has(kind):
		body.region_rect = REGIONS[kind]
		body.modulate = TINTS[kind]
	if lay_timer <= 0:
		lay_timer = _lay_interval()
	GameClock.ticked.connect(_on_tick)

func _lay_interval() -> int:
	return maxi(1, int(Balance.EGG_LAY_DAYS * GameClock.TICKS_PER_DAY))

func _on_tick() -> void:
	move_cooldown -= 1
	if move_cooldown <= 0:
		move_cooldown = MOVE_EVERY_TICKS + randi_range(0, 10)
		var next: Vector2i = cell + Pawn.DIRS.pick_random()
		if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
			cell = next
	lay_timer -= 1
	if lay_timer <= 0:
		lay_timer = _lay_interval()
		_lay_egg()

func _lay_egg() -> void:
	var egg: FoodItem = FOOD_SCENE.instantiate()  # eggs are raw food
	egg.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(egg)
	Fx.emote(self, "+", Color(1.0, 0.95, 0.75))

func _process(delta: float) -> void:
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, 6.0 * delta))
	if absf(dest.x - position.x) > 0.5:
		($Body as Sprite2D).flip_h = dest.x < position.x
