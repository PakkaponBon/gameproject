class_name Landmark
extends Node2D
## A frontier landmark on the home map (see LandmarkDefs). Sits on a cell as an
## oversized feature; stays a dim mystery until a villager passes within a few
## tiles, then reveals its name. Click it to send someone to investigate — a
## villager walks out, works it, and its reward table pays out on the spot
## (loose goods to haul home, renown, maybe a relic shard or a full relic).
## One-shot places empty for good; renewable ones (grove, cairn) come back
## after a cooldown.
##
## Built in code by WorldSpawner.spawn_landmark (no scene needed). Walkable —
## it never blocks pathing; it's a place, not an obstacle.

const SPRITES := preload("res://assets/sprites.png")
const REVEAL_RADIUS := 4  # tiles: a villager this close "comes upon" the place
const INVESTIGATE_TICKS := 80  # the work of searching it, once a villager arrives
const DIM_ALPHA := 0.55  # undiscovered: a hint on the horizon, not yet named
const DEPLETED_ALPHA := 0.3  # searched and empty (one-shot) / resting (renewable)

var def_id := ""
var cell: Vector2i
var discovered := false
var claimed := false  # investigated and emptied; renewables re-open when regrow hits 0
var regrow_ticks := 0  # renewable places: >0 means depleted, counting back to 0
var spawner_ref: WorldSpawner  # set by spawn_landmark, for dropping reward goods

var _body: Sprite2D
var _job: Job  # the live INVESTIGATE job, if one is out; null when none

func _ready() -> void:
	add_to_group("landmarks")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	_build_visual()
	if claimed and not _is_renewable():
		_apply_depleted()  # a loaded, emptied one-shot reads as spent
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

## Keeps the dim/full state in sync (called on reveal and on regrow).
func set_discovered(on: bool) -> void:
	discovered = on
	if is_instance_valid(_body):
		var tint: Color = LandmarkDefs.get_def(def_id).tint
		_body.modulate = tint if on else Color(tint.r, tint.g, tint.b, DIM_ALPHA)

func _on_tick() -> void:
	if regrow_ticks > 0:
		regrow_ticks -= 1
		if regrow_ticks == 0:
			_on_regrown()
		return
	if not discovered:
		_check_proximity()

func _check_proximity() -> void:
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
	var def := LandmarkDefs.get_def(def_id)
	var place_name: String = def.name
	var blurb: String = def.blurb
	EventBus.notice.emit("You come upon the %s. %s" % [place_name, blurb],
			Color(0.85, 0.9, 0.7), position)
	EventBus.chronicle_entry.emit("The village found the %s out beyond the fields." % place_name)

func _is_renewable() -> bool:
	return int(LandmarkDefs.get_def(def_id).renewable_days) > 0

## Player clicked this landmark: send a villager to explore it. Any free hand
## with gathering priority takes the job, walks out (revealing the place if it
## wasn't), works it, and the reward pays out on completion.
func request_investigation() -> void:
	if _job != null:
		EventBus.notice.emit("Someone is already headed for the %s." % _place_name(),
				Color(0.72, 0.74, 0.7), position)
		return
	if claimed:
		var msg := "The %s has nothing more to give." % _place_name()
		if _is_renewable():
			msg = "The %s needs time before it bears again." % _place_name()
		EventBus.notice.emit(msg, Color(0.7, 0.7, 0.7), position)
		return
	_job = Job.new()
	_job.type = Job.Type.INVESTIGATE
	_job.target = self
	_job.cell = cell
	_job.work_ticks = INVESTIGATE_TICKS
	_job.completed.connect(_on_investigated)
	JobManager.add_job(_job)
	EventBus.notice.emit("A villager sets out for the %s." % _place_name(),
			Color(0.8, 0.85, 0.7), position)

func _on_investigated() -> void:
	_job = null
	if not discovered:
		set_discovered(true)
	var def := LandmarkDefs.get_def(def_id)
	var offset := 0
	# Loose goods spill by the landmark — haulers carry them home from here.
	var resources: Dictionary = def.resources
	for res_id: String in resources:
		spawner_ref.drop_resource(cell + Vector2i(offset - 1, 2), res_id, int(resources[res_id]))
		offset += 1
	var weapons: Array = def.get("weapons", [])
	for weapon_id: String in weapons:
		spawner_ref.drop_resource(cell + Vector2i(offset - 1, 2), String(weapon_id), 1)
		offset += 1
	var renown: int = int(def.renown)
	if renown > 0:
		FactionManager.add_renown(renown)
	if randf() < float(def.shard_chance):
		spawner_ref.drop_resource(cell + Vector2i(0, 3), "relic_shard", 1)
	if randf() < float(def.relic_chance):
		spawner_ref.spawn_resource(cell + Vector2i(1, 3), String(RelicDefs.ORDER.pick_random()))
	var place := _place_name()
	EventBus.notice.emit("The %s gives up its keeping — carry it home." % place,
			Color(0.9, 0.85, 0.55), position)
	EventBus.chronicle_entry.emit("The village searched the %s, and did not come home empty." % place)
	claimed = true
	if _is_renewable():
		regrow_ticks = int(def.renewable_days) * GameClock.TICKS_PER_DAY
	_apply_depleted()

func _on_regrown() -> void:
	claimed = false
	set_discovered(discovered)  # restore full tint
	EventBus.notice.emit("The %s has come back — worth another look." % _place_name(),
			Color(0.75, 0.9, 0.6), position)

func _apply_depleted() -> void:
	if is_instance_valid(_body):
		var tint: Color = LandmarkDefs.get_def(def_id).tint
		_body.modulate = Color(tint.r, tint.g, tint.b, DEPLETED_ALPHA)

func _place_name() -> String:
	return String(LandmarkDefs.get_def(def_id).name)
