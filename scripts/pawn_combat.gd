class_name PawnCombat
extends Node
## Melee combat for one pawn: health, armor, and fighting back at raiders.
## attack_damage/armor are variables on purpose — weapons, skills, and
## traits (later Phase 4 items) modify them.

signal damaged
signal defeated

const HP_MAX := 100.0
const ATTACK_COOLDOWN_TICKS := 10
const BASE_HIT_CHANCE := 0.7
const HIT_PER_MELEE_LEVEL := 0.03   # level 10 = 100% to hit
const DAMAGE_PER_MELEE_LEVEL := 0.05  # level 10 = +50% damage
const MELEE_XP_PER_HIT := 8.0
const WOUNDED_BELOW := 0.5  # of max HP: slower work, seeks bed rest
const RECOVERED_AT := 0.9   # sleeps/heals until back to here
const HEAL_IN_BED := 0.08   # per tick while sleeping in a bed
const HEAL_ON_GROUND := 0.02

var hp := HP_MAX
var attack_damage := WeaponDefs.UNARMED_DAMAGE
var armor := 0.0
var weapon_id := ""  # "" = unarmed
var ammo := 0  # arrow shots remaining (bows only)
var relic_id := ""  # carried magic relic ("" = none)
var relic_cooldown := 0
var armor_buff := 0.0  # barrier spell
var armor_buff_ticks := 0
var attack_cooldown := 0
var attack_target: Raider = null  # draft order: pursue and engage

@onready var pawn: Pawn = get_parent()

func tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1
	if relic_cooldown > 0:
		relic_cooldown -= 1
	if armor_buff_ticks > 0:
		armor_buff_ticks -= 1
		if armor_buff_ticks <= 0:
			armor_buff = 0.0

## Attacks an adjacent raider if there is one; returns true while engaged.
func engage_adjacent() -> bool:
	var raider := _adjacent_raider()
	if raider == null:
		return false
	if attack_cooldown <= 0:
		attack_cooldown = ATTACK_COOLDOWN_TICKS
		var lvl := pawn.skills.level("melee")
		if randf() < BASE_HIT_CHANCE + HIT_PER_MELEE_LEVEL * lvl:
			var damage := attack_damage * (1.0 + DAMAGE_PER_MELEE_LEVEL * lvl) \
					* TraitDefs.multiplier(pawn.traits, "melee_damage_mult")
			raider.take_damage(damage)
			EventBus.play_sfx.emit("hit")
			pawn.skills.gain("melee", MELEE_XP_PER_HIT)  # learn by landing hits
	return true

func take_damage(amount: float) -> void:
	hp = maxf(hp - maxf(amount - armor - armor_buff, 1.0), 0.0)
	damaged.emit()
	if hp <= 0.0:
		defeated.emit()

## HP loss without the attacked reaction (starvation bleed-out etc.). No armor.
func drain(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		defeated.emit()

func heal(amount: float) -> void:
	hp = minf(hp + amount, HP_MAX)

func equip(id: String) -> void:
	weapon_id = id
	attack_damage = float(WeaponDefs.get_def(id).damage)
	pawn.update_held()

## Drop the weapon at our feet (gear reassignment via the panel).
func unequip() -> void:
	if weapon_id == "":
		return
	var item: ResourceItem = preload("res://scenes/resource_item.tscn").instantiate()
	item.resource_id = weapon_id
	item.position = WorldGrid.cell_to_world(pawn.cell)
	pawn.get_parent().add_child(item)  # pawns live in Entities now
	weapon_id = ""
	attack_damage = WeaponDefs.UNARMED_DAMAGE
	pawn.update_held()

func is_ranged() -> bool:
	return weapon_id != "" and bool(WeaponDefs.get_def(weapon_id).get("ranged", false))

## Archer behavior: shoot the nearest raider in range, kite if too close.
## Returns true if it acted this tick (caller skips other behavior).
func ranged_tick() -> bool:
	if not is_ranged() or ammo <= 0:
		return false
	var wdef := WeaponDefs.get_def(weapon_id)
	var reach := int(wdef.range) + _tower_bonus()
	var target := _nearest_raider_within(reach)
	if target == null:
		return false
	var dist := (target.cell - pawn.cell).abs()
	if dist.x + dist.y <= int(wdef.kite_range) and _tower_bonus() == 0:
		_kite_from(target)
		return true
	if attack_cooldown <= 0:
		attack_cooldown = ATTACK_COOLDOWN_TICKS + 5
		ammo -= 1
		EventBus.play_sfx.emit("bow")
		var lvl := pawn.skills.level("archery")
		if randf() < 0.6 + 0.04 * lvl:
			target.take_damage(float(wdef.damage) * (1.0 + 0.05 * lvl)
					* TraitDefs.multiplier(pawn.traits, "ranged_damage_mult"))
			pawn.skills.gain("archery", 8.0)
	return true

## Auto-cast the carried relic when its moment comes. Long cooldowns and
## scarcity keep magic decisive, not routine.
func relic_tick() -> void:
	if relic_id == "" or relic_cooldown > 0 or pawn.survival.sleeping:
		return
	var def := RelicDefs.get_def(relic_id)
	if def.has("damage"):  # fireball: blast the nearest cluster
		var target := _nearest_raider_within(int(def.range))
		if target == null:
			return
		for node in get_tree().get_nodes_in_group("raiders"):
			var raider := node as Raider
			var d := (raider.cell - target.cell).abs()
			if d.x + d.y <= int(def.radius):
				raider.take_damage(float(def.damage))
		EventBus.play_sfx.emit("spell")
		relic_cooldown = int(def.cooldown)
	elif def.has("heal"):  # mend the most wounded villager nearby
		var worst: Pawn = null
		for node in get_tree().get_nodes_in_group("pawns"):
			var other := node as Pawn
			if other.dead or other.combat.hp >= HP_MAX * 0.6:
				continue
			var d := (other.cell - pawn.cell).abs()
			if d.x + d.y <= int(def.range) and (worst == null or other.combat.hp < worst.combat.hp):
				worst = other
		if worst:
			worst.combat.heal(float(def.heal))
			EventBus.play_sfx.emit("spell")
			relic_cooldown = int(def.cooldown)
	elif def.has("armor"):  # barrier: shield nearby villagers during raids
		if not raid_active():
			return
		for node in get_tree().get_nodes_in_group("pawns"):
			var other := node as Pawn
			var d := (other.cell - pawn.cell).abs()
			if not other.dead and d.x + d.y <= int(def.radius):
				other.combat.apply_barrier(float(def.armor), int(def.duration))
		EventBus.play_sfx.emit("spell")
		relic_cooldown = int(def.cooldown)

func apply_barrier(amount: float, ticks: int) -> void:
	armor_buff = amount
	armor_buff_ticks = ticks

func _tower_bonus() -> int:
	if WorldGrid.buildings.has(pawn.cell):
		return int(BuildingDefs.get_def(WorldGrid.buildings[pawn.cell]).get("range_bonus", 0))
	return 0

func _nearest_raider_within(reach: int) -> Raider:
	var best: Raider = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		var d := (raider.cell - pawn.cell).abs()
		var manhattan := d.x + d.y
		if manhattan <= reach and float(manhattan) < best_dist:
			best = raider
			best_dist = float(manhattan)
	return best

func _kite_from(threat: Raider) -> void:
	var best := pawn.cell
	var best_dist := float((pawn.cell - threat.cell).length_squared())
	for dir in Pawn.DIRS:
		var next := pawn.cell + dir
		if WorldGrid.in_bounds(next) and not WorldGrid.is_wall(next):
			var d := float((next - threat.cell).length_squared())
			if d > best_dist:
				best_dist = d
				best = next
	if best != pawn.cell:
		pawn.cell = best
		pawn.target_cell = best

func is_wounded() -> bool:
	return hp < HP_MAX * WOUNDED_BELOW

func fully_recovered() -> bool:
	return hp >= HP_MAX * RECOVERED_AT

## One drafted tick: pursue the attack order, or execute move orders.
## engage_adjacent (run before this) lands the hits.
func drafted_tick() -> void:
	if ranged_tick():
		return  # archers shoot/kite instead of closing in
	if attack_target and not is_instance_valid(attack_target):
		attack_target = null  # target down; hold position
	if attack_target:
		var path: Array[Vector2i] = WorldGrid.astar.get_id_path(pawn.cell, attack_target.cell, true)
		if path.size() >= 2:
			pawn.cell = path[1]
		pawn.target_cell = pawn.cell
	elif pawn.cell != pawn.target_cell:
		pawn.step()

func raid_active() -> bool:
	return not get_tree().get_nodes_in_group("raiders").is_empty()

func sheltering() -> bool:
	return raid_active() and (WorldGrid.safety_cells.has(pawn.cell) or _tower_bonus() > 0)

## Undrafted raid response: archers with arrows man a tower; everyone
## else runs for the nearest safety cell.
func flee_if_raid() -> void:
	if not raid_active() or pawn.survival.food_target:
		return
	if is_ranged() and ammo > 0:
		if _tower_bonus() > 0 or _is_tower(pawn.target_cell):
			return  # manning (or heading to) a tower already
		var tower := _nearest_free_tower()
		if tower != WorldGrid.INVALID_CELL:
			pawn.abort_all(false)
			pawn.target_cell = tower
			return
	if WorldGrid.safety_cells.is_empty():
		return
	if WorldGrid.safety_cells.has(pawn.cell) or WorldGrid.safety_cells.has(pawn.target_cell):
		return
	var spot := WorldGrid.nearest_safety_cell(pawn.cell)
	if spot == WorldGrid.INVALID_CELL:
		return
	pawn.abort_all(false)  # drop work and bed claims; keep an eating trip
	pawn.target_cell = spot

func _is_tower(cell: Vector2i) -> bool:
	return WorldGrid.buildings.has(cell) \
			and BuildingDefs.get_def(WorldGrid.buildings[cell]).get("range_bonus", 0) > 0

func _nearest_free_tower() -> Vector2i:
	var best := WorldGrid.INVALID_CELL
	var best_dist := INF
	for cell: Vector2i in WorldGrid.buildings:
		if not _is_tower(cell) or _occupied_by_other(cell):
			continue
		var dist := float((cell - pawn.cell).length_squared())
		if dist < best_dist and not WorldGrid.astar.get_id_path(pawn.cell, cell).is_empty():
			best = cell
			best_dist = dist
	return best

func _occupied_by_other(cell: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("pawns"):
		var other := node as Pawn
		if other != pawn and (other.cell == cell or other.target_cell == cell):
			return true
	return false

func _adjacent_raider() -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		var d := (raider.cell - pawn.cell).abs()
		if d.x + d.y <= 1:
			return raider
	return null
