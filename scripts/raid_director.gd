class_name RaidDirector
extends Node
## Spawns a raider at a map edge on a fixed cadence and reports whether
## a raid is in progress. Scene-local to Main, not an autoload.

signal raid_started
signal raid_ended

const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const RAID_INTERVAL_TICKS := 1200  # ~2 minutes at 10 ticks/sec

var ticks_until_raid := RAID_INTERVAL_TICKS
var spawn_parent: Node2D = null  # assigned by Main

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	ticks_until_raid -= 1
	if ticks_until_raid <= 0:
		ticks_until_raid = RAID_INTERVAL_TICKS
		_spawn_raider()

func _spawn_raider() -> void:
	var raider: Raider = RAIDER_SCENE.instantiate()
	raider.position = WorldGrid.cell_to_world(_random_edge_cell())
	raider.gone.connect(_on_raider_gone)
	spawn_parent.add_child(raider)
	raid_started.emit()

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
