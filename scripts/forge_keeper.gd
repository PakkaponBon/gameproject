class_name ForgeKeeper
extends Node
## Keeps every built workstation running: picks the first recipe (by
## RecipeDefs.ORDER) whose inputs exist as free items, spawns a CraftOrder
## there, and starts the next one when it finishes. Scene-local to Main.

const ORDER_SCENE := preload("res://scenes/craft_order.tscn")
const CHECK_EVERY_TICKS := 20

var orders := {}  # workstation cell -> CraftOrder
var spawn_parent: Node2D = null  # assigned by Main
var _cooldown := 0

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	# Drop finished/canceled orders; cancel any whose station was removed.
	for cell: Vector2i in orders.keys():
		if not is_instance_valid(orders[cell]):
			orders.erase(cell)
		elif not _is_workstation(cell):
			orders[cell].cancel()
			orders.erase(cell)
	for cell: Vector2i in WorldGrid.buildings:
		if _is_workstation(cell) and not orders.has(cell):
			var recipe := _pick_recipe(WorldGrid.buildings[cell])
			if recipe != "":
				start_order(cell, recipe)

func start_order(cell: Vector2i, recipe: String) -> CraftOrder:
	var order: CraftOrder = ORDER_SCENE.instantiate()
	order.recipe_id = recipe
	order.position = WorldGrid.cell_to_world(cell)
	spawn_parent.add_child(order)
	orders[cell] = order
	return order

func _is_workstation(cell: Vector2i) -> bool:
	if not WorldGrid.buildings.has(cell):
		return false
	return bool(BuildingDefs.get_def(WorldGrid.buildings[cell]).get("workstation", false))

## Pick a recipe this station can actually make — each recipe names the
## building it belongs to, so a brewery never forges swords and vice versa.
func _pick_recipe(station_id: String) -> String:
	for id: String in RecipeDefs.ORDER:
		var def := RecipeDefs.get_def(id)
		if String(def.get("station", "")) != station_id:
			continue
		# Don't overproduce: skip recipes whose output is already stocked up.
		if _count_free(def.output) >= int(def.get("max_stock", 999)):
			continue
		if _inputs_available(def.inputs):
			return id
	return ""

func _inputs_available(inputs: Dictionary) -> bool:
	for id: String in inputs:
		if _count_free(id) < int(inputs[id]):
			return false
	return true

func _count_free(id: String) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			count += 1
	return count
