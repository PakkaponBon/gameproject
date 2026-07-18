class_name GateAnimator
extends Node
## Visual gate open/close (cosmetic only — pathing is unchanged). A gate
## eases open while a villager stands on or beside it, and eases shut once
## clear, stepping through the reserved atlas frames. Enemies never open it;
## they batter it (that logic lives in Raider). No save state — openness is
## re-derived from the world each tick.

## Closed → transition → transition → open. Cells 22–24 are the asset agent's
## gate frames (tile_03 is the closed frame).
const FRAMES := [Vector2i(3, 0), Vector2i(22, 0), Vector2i(23, 0), Vector2i(24, 0)]
const OPEN := 3
const CHECK_EVERY := 2  # ~5 steps/sec: smooth without churning the tilemap

var _openness := {}  # gate cell -> current frame index 0..3
var _cooldown := 0

@onready var main: Node2D = get_parent()
@onready var walls: TileMapLayer = main.get_node("Walls")

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY
	for cell: Vector2i in WorldGrid.buildings:
		if WorldGrid.buildings[cell] != "gate":
			continue
		var prev: int = _openness.get(cell, 0)
		var step := 1 if _villager_adjacent(cell) else -1
		var next := clampi(prev + step, 0, OPEN)
		if next != prev:
			_openness[cell] = next
			walls.set_cell(cell, main.SOURCE_ID, FRAMES[next])
	# Forget gates that were removed or deconstructed.
	for cell: Vector2i in _openness.keys():
		if not WorldGrid.buildings.has(cell) or WorldGrid.buildings[cell] != "gate":
			_openness.erase(cell)

func _villager_adjacent(cell: Vector2i) -> bool:
	for pawn: Pawn in main.pawns:
		if pawn.dead:
			continue
		var d := (pawn.cell - cell).abs()
		if d.x + d.y <= 1:
			return true
	return false
