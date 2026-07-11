class_name Merchant
extends Node2D
## A traveling trader: walks in from the edge, lingers near the village
## center, then leaves. Click to trade. This is the trade primitive that
## Phase 6 diplomacy reuses.

const MOVE_EVERY_TICKS := 2
const VISIT_TICKS := 1500  # ~2.5 minutes of browsing time

var cell: Vector2i
var exit_cell: Vector2i  # set before add_child
var visit_ticks_left := VISIT_TICKS
var relic_in_stock := ""  # one rare relic per visit
var leaving := false
var move_cooldown := 0

func _ready() -> void:
	add_to_group("merchants")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	relic_in_stock = RelicDefs.ORDER.pick_random()
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	var dest := WorldGrid.MAP_SIZE / 2 if not leaving else exit_cell
	if cell == dest or (not leaving and (dest - cell).abs().x + (dest - cell).abs().y <= 2):
		if leaving:
			EventBus.merchant_left.emit()
			queue_free()
			return
		visit_ticks_left -= 1
		if visit_ticks_left <= 0:
			leaving = true
		return
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS
	# Friendly: walks the villager grid, so gates are open to it.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, dest, true)
	if path.size() >= 2:
		cell = path[1]
	elif not leaving:
		visit_ticks_left -= 10  # stuck outside; give up sooner

func _process(delta: float) -> void:
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, 10.0 * delta))
