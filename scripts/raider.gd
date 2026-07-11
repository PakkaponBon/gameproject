class_name Raider
extends Node2D
## Raid enemy: chases the nearest living pawn and attacks in melee.
## Walls block it, so player-built defenses matter.

signal gone  # died or left; main uses this to clear the event banner

const LERP_WEIGHT := 10.0
const HP_MAX := 50.0
const SWORD_DROP_CHANCE := 0.4
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const ATTACK_COOLDOWN_TICKS := 10
const MOVE_EVERY_TICKS := 2  # half pawn speed so pawns can disengage

var cell: Vector2i
var hp := HP_MAX
var attack_damage := 8.0
var armor := 0.0
var is_boss := false  # set before add_child: tougher, drops a relic
var faction_id := ""  # who sent this bandit (attrition on death)
var attack_cooldown := 0
var move_cooldown := 0

func _ready() -> void:
	add_to_group("raiders")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	if is_boss:
		hp = 90.0
		attack_damage = 12.0
		var body: Sprite2D = $Body
		body.modulate = Color(0.4, 0.1, 0.1)
		body.scale = Vector2(1.3, 1.3)
	GameClock.ticked.connect(_on_tick)

func take_damage(amount: float) -> void:
	hp -= maxf(amount - armor, 1.0)
	if hp <= 0.0:
		if faction_id != "":
			FactionManager.on_bandit_killed(faction_id)
		if is_boss:
			_drop_item(RelicDefs.ORDER.pick_random())  # the relic faucet
		if randf() < SWORD_DROP_CHANCE:
			_drop_item("sword")
		gone.emit()
		queue_free()

func _drop_item(id: String) -> void:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = id
	item.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(item)

func _on_tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1
	# Fight whatever defender is closest — villager or allied warrior.
	# Variant on purpose: Pawn and Ally share cell/take_damage by shape.
	var target: Variant = _nearest_living_pawn()
	var ally := _nearest_ally()
	if ally != null and (target == null \
			or (ally.cell - cell).length_squared() < (target.cell - cell).length_squared()):
		target = ally
	if target == null:
		gone.emit()  # no one left to fight
		queue_free()
		return
	var target_cell: Vector2i = target.cell
	var d := (target_cell - cell).abs()
	if d.x + d.y <= 1:
		_attack_defender(target)
		return
	move_cooldown -= 1
	# Enemy grid: gates count as solid, so a gated wall blocks the path —
	# but blocked bandits batter the nearest gate down.
	var path: Array[Vector2i] = WorldGrid.astar_enemy.get_id_path(cell, target_cell, true)
	if path.size() >= 2:
		if move_cooldown <= 0:
			move_cooldown = MOVE_EVERY_TICKS
			cell = path[1]
		return
	var gate := _nearest_breakable()
	if gate == WorldGrid.INVALID_CELL:
		return  # sealed solid: walls are absolute; pace outside
	var gd := (gate - cell).abs()
	if gd.x + gd.y <= 1:
		_attack_gate(gate)
		return
	if move_cooldown <= 0:
		move_cooldown = MOVE_EVERY_TICKS
		var gpath: Array[Vector2i] = WorldGrid.astar_enemy.get_id_path(cell, gate, true)
		if gpath.size() >= 2:
			cell = gpath[1]

func _attack_defender(target: Variant) -> void:
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_COOLDOWN_TICKS
	target.take_damage(attack_damage)

func _nearest_ally() -> Ally:
	var best: Ally = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("allies"):
		var ally := node as Ally
		var dist := float((ally.cell - cell).length_squared())
		if dist < best_dist:
			best = ally
			best_dist = dist
	return best

func _attack_gate(gate: Vector2i) -> void:
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_COOLDOWN_TICKS
	WorldGrid.damage_building(gate, attack_damage)

func _nearest_breakable() -> Vector2i:
	var best := WorldGrid.INVALID_CELL
	var best_dist := INF
	for gcell: Vector2i in WorldGrid.building_hp:
		var dist := float((gcell - cell).length_squared())
		if dist < best_dist:
			best = gcell
			best_dist = dist
	return best

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
