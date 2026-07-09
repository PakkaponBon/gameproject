class_name Raider
extends Node2D
## Raid enemy: chases the nearest living pawn and attacks in melee.
## Walls block it, so player-built defenses matter.

signal gone  # died or left; main uses this to clear the event banner

const LERP_WEIGHT := 10.0
const HP_MAX := 50.0
const ATTACK_DAMAGE := 8.0
const ATTACK_COOLDOWN_TICKS := 10
const MOVE_EVERY_TICKS := 2  # half pawn speed so pawns can disengage

var cell: Vector2i
var hp := HP_MAX
var attack_cooldown := 0
var move_cooldown := 0

func _ready() -> void:
	add_to_group("raiders")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		gone.emit()
		queue_free()

func _on_tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1
	var target := _nearest_living_pawn()
	if target == null:
		gone.emit()  # no one left to fight
		queue_free()
		return
	var d := (target.cell - cell).abs()
	if d.x + d.y <= 1:
		_attack(target)
		return
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS
	# Enemy grid: gates count as solid, so a gated wall keeps raiders out.
	var path: Array[Vector2i] = WorldGrid.astar_enemy.get_id_path(cell, target.cell, true)
	if path.size() >= 2:
		cell = path[1]

func _attack(pawn: Pawn) -> void:
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_COOLDOWN_TICKS
	pawn.take_damage(ATTACK_DAMAGE)

func _nearest_living_pawn() -> Pawn:
	var best: Pawn = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("pawns"):
		var pawn := node as Pawn
		if pawn.dead:
			continue
		var dist := float((pawn.cell - cell).length_squared())
		if dist < best_dist:
			best = pawn
			best_dist = dist
	return best

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
