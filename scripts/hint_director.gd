class_name HintDirector
extends Node
## Soft tutorial (POLISH.md): six contextual hints, each shown once,
## never modal — they ride the notification feed in a distinct color.

const HINT_COLOR := Color(0.55, 0.85, 1.0)
const CHECK_EVERY_TICKS := 10

var _shown := {}
var _cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	if GameClock.ticks > 100 and WorldGrid.fields.is_empty():
		_hint("field", "Villagers work on their own — zone a farm field [F] before the wild food runs out.")
	if GameClock.day_fraction() > 0.5 and not _has_building("sleep_spot"):
		_hint("beds", "Night is coming. Build beds [B] — villagers heal and rest faster in them.")
	if _count_free("wood") >= 5 and WorldGrid.buildings.is_empty():
		_hint("walls", "Bandits will come. Raise walls with a gate [B] to make them fight where you choose.")
	if not get_tree().get_nodes_in_group("raiders").is_empty():
		_hint("draft", "RAID! Draft villagers [R] (or right-click the roster) and meet them at your gate.")
	if _anyone_wounded() and _count_free("herb") == 0:
		_hint("herbs", "Someone is hurt. Bed rest heals — healing herbs [F] heal faster.")
	if _count_free("iron_ore") > 0 and not _has_building("workstation"):
		_hint("forge", "You have iron ore. Build a forge [B] to smelt it into swords and bows.")
	if GameClock.season_index() == 2 and not _has_building("warmth_radius"):
		_hint("hearth", "Winter is coming. Wall in a room and build a hearth [B] — cold villagers slow down and sour.")
	if GameClock.total_days() >= 3 and not _has_building("livestock"):
		_hint("coop", "Food comes and goes. A Chicken Coop [B] lays eggs every day — steady food, no field needed.")
	if main.raid_director.raid_count >= 1 and not _has_building_id("loom"):
		_hint("armor", "Raids grow with your renown. A Loom [B] weaves wool and hide into armor for your fighters.")
	if main.raid_director.raid_count >= 2 and WorldGrid.traps.is_empty():
		_hint("traps", "Lay Spike Pits [B] on the raiders' path — your own villagers walk around them.")

func _hint(id: String, text: String) -> void:
	if _shown.has(id):
		return
	_shown[id] = true
	main.hud.set_event("TIP: " + text, HINT_COLOR)

func _has_building(flag: String) -> bool:
	for cell: Vector2i in WorldGrid.buildings:
		if BuildingDefs.get_def(WorldGrid.buildings[cell]).get(flag, false):
			return true
	return false

func _has_building_id(id: String) -> bool:
	for cell: Vector2i in WorldGrid.buildings:
		if WorldGrid.buildings[cell] == id:
			return true
	return false

func _anyone_wounded() -> bool:
	for pawn: Pawn in main.pawns:
		if pawn.combat.is_wounded():
			return true
	return false

func _count_free(id: String) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not (item.get_parent() is Pawn):
			total += 1
	return total
