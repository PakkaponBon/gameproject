class_name RaidDirector
extends Node
## Spawns a raider at a map edge on a fixed cadence and reports whether
## a raid is in progress. Scene-local to Main, not an autoload.

signal raid_started(faction_name: String)
signal raid_ended

const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const ALLY_SCENE := preload("res://scenes/ally.tscn")
const RAID_INTERVAL_TICKS := 1200  # ~2 minutes at 10 ticks/sec
const ALLY_HELP_AT := 4  # allied warriors join defenses this size and up
const ALLY_COUNT := 2

var ticks_until_raid := RAID_INTERVAL_TICKS
var raid_count := 0
var spawn_parent: Node2D = null  # assigned by Main

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	ticks_until_raid -= 1
	if ticks_until_raid <= 0:
		ticks_until_raid = RAID_INTERVAL_TICKS
		_spawn_raid()

func _spawn_raid() -> void:
	# Raids come from a hostile faction; a realm at peace sends none.
	var faction_id := FactionManager.pick_raid_faction()
	if faction_id == "":
		return
	raid_count += 1
	var count := FactionManager.raid_size(faction_id)
	var origin := _random_edge_cell()
	var placed := 0
	for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT,
			Vector2i.RIGHT, Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]:
		if placed >= count:
			break
		var cell := origin + offset
		if WorldGrid.in_bounds(cell) and not WorldGrid.is_wall(cell):
			_spawn_bandit(cell, faction_id, placed == 0 and count >= 4)  # big raids bring a boss
			placed += 1
	if count >= ALLY_HELP_AT and FactionManager.has_ally():
		_spawn_allies()
	raid_started.emit(FactionDefs.get_def(faction_id).name)

func _spawn_bandit(cell: Vector2i, faction_id: String, boss := false) -> void:
	var raider: Raider = RAIDER_SCENE.instantiate()
	raider.is_boss = boss
	raider.faction_id = faction_id
	raider.position = WorldGrid.cell_to_world(cell)
	raider.gone.connect(_on_raider_gone)
	spawn_parent.add_child(raider)

func _spawn_allies() -> void:
	var center := WorldGrid.MAP_SIZE / 2
	for i in ALLY_COUNT:
		var cell := center + Vector2i(randi_range(-6, 6), randi_range(-6, 6))
		if not WorldGrid.in_bounds(cell) or WorldGrid.is_wall(cell):
			cell = center
		var ally: Ally = ALLY_SCENE.instantiate()
		ally.position = WorldGrid.cell_to_world(cell)
		spawn_parent.add_child(ally)

func _on_raider_gone() -> void:
	# The departing raider is still in the group at this moment.
	if get_tree().get_nodes_in_group("raiders").size() <= 1:
		raid_ended.emit()

func _random_edge_cell() -> Vector2i:
	var s := WorldGrid.MAP_SIZE
	for _attempt in 20:
		var cell := Vector2i(randi() % s.x, 0)
		match randi() % 4:
			1: cell = Vector2i(randi() % s.x, s.y - 1)
			2: cell = Vector2i(0, randi() % s.y)
			3: cell = Vector2i(s.x - 1, randi() % s.y)
		if not WorldGrid.is_wall(cell):
			return cell
	return Vector2i(s.x / 2, 0)
