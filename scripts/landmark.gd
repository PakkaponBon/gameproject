class_name Landmark
extends Node2D
## A frontier landmark on the home map (see LandmarkDefs). Sits on a cell as an
## oversized feature; stays a dim mystery until a villager passes within a few
## tiles, then reveals its name. Investigating it for a reward is F2.
##
## Built in code by WorldSpawner.spawn_landmark (no scene needed). Walkable —
## it never blocks pathing; it's a place, not an obstacle.

const SPRITES := preload("res://assets/sprites.png")
const REVEAL_RADIUS := 4  # tiles: a villager this close "comes upon" the place
const DIM_ALPHA := 0.55  # undiscovered: a hint on the horizon, not yet named

var def_id := ""
var cell: Vector2i
var discovered := false
var claimed := false  # investigated and emptied (F2)
var regrow_ticks := 0  # renewable places: >0 means depleted, counting back (F2)

var _body: Sprite2D

func _ready() -> void:
	add_to_group("landmarks")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	_build_visual()
	if not discovered:
		GameClock.ticked.connect(_on_tick)

func _build_visual() -> void:
	var def := LandmarkDefs.get_def(def_id)
	var atlas_cell: int = def.cell
	var tint: Color = def.tint
	var render_scale: float = def.scale
	_body = Sprite2D.new()
	_body.texture = SPRITES
	_body.region_enabled = true
	_body.region_rect = Rect2(atlas_cell * 16, 0, 16, 16)
	_body.scale = Vector2.ONE * render_scale
	_body.modulate = tint if discovered else Color(tint.r, tint.g, tint.b, DIM_ALPHA)
	add_child(_body)

## Called by the spawner/save-restore before _ready runs its visual, or after
## for a loaded-discovered landmark. Keeps the dim/full state in sync.
func set_discovered(on: bool) -> void:
	discovered = on
	if is_instance_valid(_body):
		var def := LandmarkDefs.get_def(def_id)
		var tint: Color = def.tint
		_body.modulate = tint if on else Color(tint.r, tint.g, tint.b, DIM_ALPHA)

func _on_tick() -> void:
	for node in get_tree().get_nodes_in_group("pawns"):
		var pawn := node as Pawn
		if pawn.dead:
			continue
		if (pawn.cell - cell).length_squared() <= REVEAL_RADIUS * REVEAL_RADIUS:
			_reveal()
			return

func _reveal() -> void:
	if discovered:
		return
	set_discovered(true)
	if GameClock.ticked.is_connected(_on_tick):
		GameClock.ticked.disconnect(_on_tick)
	var def := LandmarkDefs.get_def(def_id)
	var place_name: String = def.name
	var blurb: String = def.blurb
	EventBus.notice.emit("You come upon the %s. %s" % [place_name, blurb],
			Color(0.85, 0.9, 0.7), position)
	EventBus.chronicle_entry.emit("The village found the %s out beyond the fields." % place_name)
