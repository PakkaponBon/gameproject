class_name RaidDirector
extends Node
## Spawns a raider at a map edge on a fixed cadence and reports whether
## a raid is in progress. Scene-local to Main, not an autoload.

signal raid_started(faction_name: String)
signal raid_warning  # scouts spotted: ~1 real minute to prepare
signal raid_ended
signal bell_rang(world_pos: Vector2)  # an alarm bell noticed a raider

const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const ALLY_SCENE := preload("res://scenes/ally.tscn")
const RAID_INTERVAL_MIN := 1700  # cadence varies so raids never feel clockwork
const RAID_INTERVAL_MAX := 2600
const RAID_WARNING_TICKS := 600  # scouts spotted ~1 real minute ahead
## First raid lands at the end of day 2 (POLISH.md): guaranteed small,
## an early taste of danger that's survivable unarmed.
const FIRST_RAID_AT := int(GameClock.TICKS_PER_DAY * 2.7)
const EARLY_RAIDS := 3  # the first few raids come from the weakest enemy
const ALLY_HELP_AT := 4  # allied warriors join defenses this size and up
const ALLY_COUNT := 2

var ticks_until_raid := FIRST_RAID_AT
var raid_count := 0
var spawn_parent: Node2D = null  # assigned by Main

var _warned := false
var _rung := {}  # bell cell -> true; cleared when the field is quiet
var _bell_check := 0

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_bell_check -= 1
	if _bell_check <= 0:
		_bell_check = 15
		_check_bells()
	if Balance.peaceful():
		return  # the realm sleeps
	ticks_until_raid -= 1
	# Tension beat: the player gets a warning window to draft and repair.
	if not _warned and ticks_until_raid <= RAID_WARNING_TICKS and ticks_until_raid > 0 \
			and FactionManager.pick_raid_faction(false) != "":
		_warned = true
		raid_warning.emit()
	if ticks_until_raid <= 0:
		ticks_until_raid = int(randi_range(RAID_INTERVAL_MIN, RAID_INTERVAL_MAX) \
				* Balance.raid_interval_mult())
		_warned = false
		_spawn_raid()

func _spawn_raid() -> void:
	# Raids come from a hostile faction; a realm at peace sends none.
	var faction_id := FactionManager.pick_raid_faction(raid_count < EARLY_RAIDS)
	if faction_id == "":
		return
	raid_count += 1
	# Escalate with survival AND prosperity: what you have is worth taking.
	var count := mini(FactionManager.raid_size(faction_id), 2 + raid_count + _wealth_pressure())
	if raid_count == 1:
		count = 2
	var origin := _random_edge_cell()
	var placed := 0
	for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT,
			Vector2i.RIGHT, Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]:
		if placed >= count:
			break
		var cell := origin + offset
		if WorldGrid.in_bounds(cell) and not WorldGrid.is_wall(cell):
			var raider := _spawn_bandit(cell, faction_id, placed == 0 and count >= 4)
			if count >= 3 and placed % 3 == 2:
				raider.make_looter()  # every third bandit is after your goods
			elif faction_id == "ashen_legion" and count >= 5 and placed % 2 == 1:
				raider.make_elite()  # the Cindermarked send armored ranks
			placed += 1
	if count >= ALLY_HELP_AT and FactionManager.has_ally():
		_spawn_allies()
	EventBus.play_sfx.emit("horn")
	raid_started.emit(FactionDefs.get_def(faction_id).name)

## Each alarm bell rings once per raid when a raider comes within its
## radius — early warning for players who missed the scout line.
func _check_bells() -> void:
	var raiders := get_tree().get_nodes_in_group("raiders")
	if raiders.is_empty():
		_rung.clear()
		return
	for cell: Vector2i in WorldGrid.buildings:
		if _rung.has(cell):
			continue
		var def: Dictionary = BuildingDefs.get_def(WorldGrid.buildings[cell])
		if not def.has("alarm_radius"):
			continue
		var radius := int(def.alarm_radius)
		for node in raiders:
			var d := ((node as Raider).cell - cell).abs()
			if maxi(d.x, d.y) <= radius:
				_rung[cell] = true
				EventBus.play_sfx.emit("horn")
				bell_rang.emit(WorldGrid.cell_to_world(cell))
				break

## Prosperity attracts trouble: raids scale with what you've built, not
## just how long you've survived.
func _wealth_pressure() -> int:
	return clampi(WorldGrid.buildings.size() / 12 + FactionManager.renown / 3, 0, 3)

## A beast pack (ash-wolves): no faction, no warning scouts — winter's own
## raid. They share the raiders group, so defenses and raid_ended apply.
func spawn_beast_pack(count: int) -> void:
	var origin := _random_edge_cell()
	var placed := 0
	for offset: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT,
			Vector2i.RIGHT, Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]:
		if placed >= count:
			break
		var cell := origin + offset
		if WorldGrid.in_bounds(cell) and not WorldGrid.is_wall(cell):
			var wolf := _spawn_bandit(cell, "")
			wolf.make_wolf()
			placed += 1
	EventBus.play_sfx.emit("horn")

func _spawn_bandit(cell: Vector2i, faction_id: String, boss := false) -> Raider:
	var raider: Raider = RAIDER_SCENE.instantiate()
	raider.is_boss = boss
	raider.faction_id = faction_id
	raider.position = WorldGrid.cell_to_world(cell)
	raider.gone.connect(_on_raider_gone)
	spawn_parent.add_child(raider)
	return raider

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
