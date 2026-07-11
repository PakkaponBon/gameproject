class_name Ally
extends Node2D
## An allied faction's warrior: arrives with big raids, hunts bandits,
## leaves when the fighting ends. Walks the villager grid (gates open).

const HP_MAX := 60.0
const ATTACK_DAMAGE := 10.0
const ATTACK_COOLDOWN_TICKS := 10
const MOVE_EVERY_TICKS := 2
const LERP_WEIGHT := 10.0

var cell: Vector2i
var hp := HP_MAX
var attack_cooldown := 0
var move_cooldown := 0

func _ready() -> void:
	add_to_group("allies")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		queue_free()

func _on_tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1
	var target := _nearest_raider()
	if target == null:
		queue_free()  # fighting's done; they ride home
		return
	var d := (target.cell - cell).abs()
	if d.x + d.y <= 1:
		if attack_cooldown <= 0:
			attack_cooldown = ATTACK_COOLDOWN_TICKS
			target.take_damage(ATTACK_DAMAGE)
		return
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target.cell, true)
	if path.size() >= 2:
		cell = path[1]

func _nearest_raider() -> Raider:
	var best: Raider = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		var dist := float((raider.cell - cell).length_squared())
		if dist < best_dist:
			best = raider
			best_dist = dist
	return best

func _process(delta: float) -> void:
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
