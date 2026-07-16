class_name Livestock
extends Node2D
## Farm animals: wander like critters but productive on a timer — hens lay
## eggs (raw food), sheep grow wool (a resource for the loom). Kind-driven
## data below; no breeding — you acquire animals by building their home.

const MOVE_EVERY_TICKS := 6
const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const KINDS := {
	"chicken": {"region": Rect2(384, 0, 16, 16), "tint": Color(1.05, 1.0, 0.85),
			"product": "", "days": Balance.EGG_LAY_DAYS},  # "" = food (an egg)
	"sheep": {"region": Rect2(368, 0, 16, 16), "tint": Color(1.15, 1.13, 1.05),
			"product": "wool", "days": Balance.WOOL_DAYS},
}

var cell: Vector2i
var kind := "chicken"  # set before add_child
var move_cooldown := 0
var lay_timer := 0  # ticks until the next product (persisted)

func _ready() -> void:
	add_to_group("livestock")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var body: Sprite2D = $Body
	if KINDS.has(kind):
		body.region_rect = KINDS[kind].region
		body.modulate = KINDS[kind].tint
	if lay_timer <= 0:
		lay_timer = _lay_interval()
	GameClock.ticked.connect(_on_tick)

func _lay_interval() -> int:
	return maxi(1, int(float(KINDS[kind].days) * GameClock.TICKS_PER_DAY))

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
		_produce()

func _produce() -> void:
	var product := String(KINDS[kind].product)
	if product == "":
		var egg: FoodItem = FOOD_SCENE.instantiate()  # eggs are raw food
		egg.position = WorldGrid.cell_to_world(cell)
		get_parent().add_child(egg)
	else:
		var item: ResourceItem = RESOURCE_SCENE.instantiate()
		item.resource_id = product
		item.position = WorldGrid.cell_to_world(cell)
		get_parent().add_child(item)
	Fx.emote(self, "+", Color(1.0, 0.95, 0.75))

func _process(delta: float) -> void:
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, 6.0 * delta))
	if absf(dest.x - position.x) > 0.5:
		($Body as Sprite2D).flip_h = dest.x < position.x
