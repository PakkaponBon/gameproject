class_name Critter
extends Node2D
## Harmless ambient life (rabbit, bird): wanders, flees nothing, does
## nothing. Life, not systems — pure Phase 13 set dressing.

const MOVE_EVERY_TICKS := 4

var cell: Vector2i
var move_cooldown := 0

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS + randi_range(0, 12)
	var next: Vector2i = cell + Pawn.DIRS.pick_random()
	if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
		cell = next

func _process(delta: float) -> void:
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, 6.0 * delta))
	if absf(dest.x - position.x) > 0.5:
		($Body as Sprite2D).flip_h = dest.x < position.x
