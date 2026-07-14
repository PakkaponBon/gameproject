class_name EventsDirector
extends Node
## Small morning events: frost snaps and refugee arrivals. Tribute
## ultimatums already live in FactionManager. Scene-local to Main.

const FROST_CHANCE := 0.08
const REFUGEE_BASE_CHANCE := 0.05
const REFUGEE_RENOWN_BONUS := 0.02  # per renown point
const VILLAGER_CAP := 15  # per GAME_DESIGN

var spawn_parent: Node2D = null  # assigned by Main

@onready var main: Node2D = get_parent()

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)

const BARD_CHANCE := 0.07
const STAR_CHANCE := 0.04

func _on_day_started(_day: int) -> void:
	if GameClock.season_index() != 3 and randf() < FROST_CHANCE:
		_frost_snap()
	var refugee_chance := REFUGEE_BASE_CHANCE + REFUGEE_RENOWN_BONUS * FactionManager.renown
	if main.pawns.size() < VILLAGER_CAP and randf() < minf(refugee_chance, 0.3):
		_refugee_arrives()
	if randf() < BARD_CHANCE:
		_bard_visits()
	if randf() < STAR_CHANCE:
		_star_falls()

func _bard_visits() -> void:
	for pawn: Pawn in main.pawns:
		pawn.needs.celebrate()
	main.hud.set_event("A wandering bard plays through the evening. Spirits lift.",
			Color(0.8, 0.7, 0.95))
	EventBus.chronicle_entry.emit("A bard sang of far places, and for one night the meadow felt bigger.")

## A relic falls from the sky somewhere wild — go claim it before winter
## buries it (or don't; it isn't going anywhere, but it feels urgent).
func _star_falls() -> void:
	var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
	if WorldGrid.is_wall(cell) or WorldGrid.items.has(cell):
		return  # the sky misses this year
	main.spawner.spawn_resource(cell, RelicDefs.ORDER.pick_random())
	main.hud.set_event("A star fell in the night — something glitters where it landed.",
			Color(0.7, 0.9, 1.0), WorldGrid.cell_to_world(cell))
	EventBus.chronicle_entry.emit("A star fell beyond the fields. The bold went looking.")

func _frost_snap() -> void:
	var killed := 0
	for node in get_tree().get_nodes_in_group("crops"):
		if randf() < 0.5:
			(node as Crop).kill()
			killed += 1
	if killed > 0:
		main.hud.set_event("An unseasonal frost kills %d crops!" % killed, Color(0.6, 0.8, 1.0))
		main.field_keeper.sync_all()  # replant the emptied cells

func _refugee_arrives() -> void:
	var edge := Vector2i(randi() % WorldGrid.MAP_SIZE.x, 0)
	if WorldGrid.is_wall(edge):
		edge = WorldGrid.MAP_SIZE / 2
	var pawn: Pawn = main.spawner.create_pawn(edge, main.spawner.unused_name(),
			{Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1})
	var pool := TraitDefs.BACKSTORIES.duplicate()
	pawn.traits = [pool.pick_random()]
	pawn.skills.xp["melee"] = float(randi_range(0, 200))
	pawn.skills.xp["archery"] = float(randi_range(0, 300))
	main.hud.set_event("%s heard of your village and asks to stay." % pawn.name,
			Color(0.7, 0.95, 0.7))
	EventBus.chronicle_entry.emit("%s arrived at the gate with nothing, and stayed." % pawn.name)
