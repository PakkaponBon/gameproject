class_name Raider
extends Node2D
## Raid enemy: chases the nearest living pawn and attacks in melee.
## Walls block it, so player-built defenses matter.

signal gone  # died or left; main uses this to clear the event banner

const LERP_WEIGHT := 7.0  # matches the slower sim tick
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
var is_looter := false  # grabs your goods and runs for the edge
var is_beast := false  # ash-wolf: fast, fragile, can't batter gates
var is_elite := false  # Legion rank: armored, tougher
var carrying_loot := false
var faction_id := ""  # who sent this bandit (attrition on death)
var attack_cooldown := 0
var move_cooldown := 0
var slow_ticks := 0  # frost relic: acts every other tick while > 0
var _slow_parity := false

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
	hp *= Balance.enemy_hp_mult()
	attack_damage *= Balance.enemy_damage_mult()
	if is_looter:
		make_looter()
	GameClock.ticked.connect(_on_tick)

## Looters read differently at a glance: mossy hood, lighter build.
func make_looter() -> void:
	is_looter = true
	($Body as Sprite2D).modulate = Color(0.55, 0.62, 0.38)

## Ash-wolf: a beast, not a bandit. Fast and fragile, hits softer, can't
## batter gates — walls fully answer a wolf winter.
func make_wolf() -> void:
	is_beast = true
	hp = 30.0 * Balance.enemy_hp_mult()
	attack_damage = 6.0 * Balance.enemy_damage_mult()
	move_cooldown = 0
	var body: Sprite2D = $Body
	body.region_rect = Rect2(368, 0, 16, 16)  # four-legged silhouette
	body.modulate = Color(0.5, 0.52, 0.58)  # ash-gray
	body.scale = Vector2(1.2, 1.2)

## Legion elite: armored rank in the Cindermarked's big raids.
func make_elite() -> void:
	is_elite = true
	armor = 4.0
	hp += 20.0
	($Body as Sprite2D).modulate = Color(0.42, 0.16, 0.2)  # deep legion red

func take_damage(amount: float) -> void:
	Fx.flash($Body)
	Fx.damage_number(self, amount)
	Fx.hit_spark(get_parent(), position)
	hp -= maxf(amount - armor, 1.0)
	if hp <= 0.0:
		if faction_id != "":
			FactionManager.on_bandit_killed(faction_id)
		if is_beast:
			_drop_meat()  # a felled wolf feeds the village
		else:
			if is_boss:
				_drop_item(RelicDefs.ORDER.pick_random())  # the relic faucet
			if carrying_loot:
				_drop_item("wood")  # cut down mid-theft: the goods stay home
			if randf() < SWORD_DROP_CHANCE:
				_drop_item(_weapon_drop())
		gone.emit()
		queue_free()

## Fallen raiders leave a mix of tier-1 arms (swords common, the crushing
## warhammer rare) — so the armory grows from what you kill.
const WEAPON_DROPS := ["sword", "sword", "club", "club", "spear", "warhammer"]

func _weapon_drop() -> String:
	return String(WEAPON_DROPS.pick_random())

func _drop_meat() -> void:
	var meat: FoodItem = preload("res://scenes/food_item.tscn").instantiate()
	meat.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(meat)

func _drop_item(id: String) -> void:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = id
	item.position = WorldGrid.cell_to_world(cell)
	get_parent().add_child(item)

## Frost relic: chilled. Longest chill wins if hit again.
func apply_slow(ticks: int) -> void:
	slow_ticks = maxi(slow_ticks, ticks)
	Fx.emote(self, "*", Color(0.6, 0.8, 1.0))

func _on_tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1
	# Chilled: skip every other tick — half move and attack speed.
	if slow_ticks > 0:
		slow_ticks -= 1
		_slow_parity = not _slow_parity
		if _slow_parity:
			return
	if is_looter and _looter_tick():
		return
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
			move_cooldown = 1 if is_beast else MOVE_EVERY_TICKS  # wolves lope
			cell = path[1]
			WorldGrid.trigger_trap(cell, self)  # spike pits bite (may free us)
		return
	if is_beast:
		return  # beasts can't batter gates: walls fully answer a wolf winter
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

## Looter behavior: grab the nearest loose item and sprint for the map
## edge. Returns false to fall back to fighting when there's nothing to
## steal (or no way to reach it).
func _looter_tick() -> bool:
	if carrying_loot:
		var exit := _nearest_edge()
		if cell == exit:
			gone.emit()  # away with the goods
			queue_free()
			return true
		_step_toward(exit)
		return true
	var prize := _nearest_loose_item()
	if prize == null:
		return false
	if prize.cell == cell:
		prize.queue_free()
		carrying_loot = true
		Fx.emote(self, "!", Color(1.0, 0.85, 0.3))
		EventBus.raider_stole.emit(position)
		return true
	var path: Array[Vector2i] = WorldGrid.astar_enemy.get_id_path(cell, prize.cell, true)
	if path.size() < 2:
		return false  # sealed away from the goods: act like a fighter
	_step_toward(prize.cell)
	return true

func _step_toward(target_cell: Vector2i) -> void:
	move_cooldown -= 1
	if move_cooldown > 0:
		return
	move_cooldown = MOVE_EVERY_TICKS
	var path: Array[Vector2i] = WorldGrid.astar_enemy.get_id_path(cell, target_cell, true)
	if path.size() >= 2:
		cell = path[1]
		WorldGrid.trigger_trap(cell, self)  # looters aren't spared the spikes

func _nearest_loose_item() -> ResourceItem:
	var best: ResourceItem = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.get_parent() is Pawn:
			continue
		var dist := float((item.cell - cell).length_squared())
		if dist < best_dist:
			best = item
			best_dist = dist
	return best

func _nearest_edge() -> Vector2i:
	var s := WorldGrid.MAP_SIZE
	var options: Array[Vector2i] = [Vector2i(cell.x, 0), Vector2i(cell.x, s.y - 1),
			Vector2i(0, cell.y), Vector2i(s.x - 1, cell.y)]
	var best := options[0]
	for option in options:
		if (option - cell).length_squared() < (best - cell).length_squared():
			best = option
	return best

func _attack_defender(target: Variant) -> void:
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_COOLDOWN_TICKS
	Fx.lunge($Body, (target as Node2D).position - position)
	target.take_damage(attack_damage)
	EventBus.play_sfx.emit("hit")

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
	Fx.lunge($Body, WorldGrid.cell_to_world(gate) - position)
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
	# Rendering only: ease toward the logical cell; procedural bob + lean
	# while moving (single-frame art, same trick as the pawns).
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, LERP_WEIGHT * delta))
	var body: Sprite2D = $Body
	if absf(dest.x - position.x) > 0.5:
		body.flip_h = dest.x < position.x
	if body.has_meta("lunging"):
		return
	var t := Time.get_ticks_msec() / 1000.0
	if position.distance_to(dest) > 1.5:
		body.position.y = -absf(sin(t * 8.0)) * 2.0
		body.rotation = sin(t * 8.0) * 0.08
	else:
		body.position.y = 0.0
		body.rotation = 0.0
