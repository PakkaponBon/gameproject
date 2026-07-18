class_name ForgeKeeper
extends Node
## Keeps every built workstation running: picks the first recipe (by
## RecipeDefs.ORDER) whose inputs exist as free items, spawns a CraftOrder
## there, and starts the next one when it finishes. Scene-local to Main.

const ORDER_SCENE := preload("res://scenes/craft_order.tscn")
const CHECK_EVERY_TICKS := 20

var orders := {}  # workstation cell -> CraftOrder
var forced := {}  # workstation cell -> recipe id the player pinned ("auto" = default)
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
	for cell: Vector2i in forced.keys():  # forget pins on removed stations
		if not _is_workstation(cell):
			forced.erase(cell)
	for cell: Vector2i in WorldGrid.buildings:
		if _is_workstation(cell) and not orders.has(cell):
			var recipe := _pick_recipe(WorldGrid.buildings[cell], cell)
			if recipe != "":
				start_order(cell, recipe)

## Right-click a workstation to cycle what it makes: auto → each recipe it
## can run → back to auto. Returns the human-readable new setting.
func cycle_recipe(cell: Vector2i) -> String:
	if not _is_workstation(cell):
		return ""
	var station: String = WorldGrid.buildings[cell]
	var options: Array[String] = ["auto"]
	for id: String in RecipeDefs.ORDER:
		if String(RecipeDefs.get_def(id).get("station", "")) == station:
			options.append(id)
	var cur: String = forced.get(cell, "auto")
	forced[cell] = options[(options.find(cur) + 1) % options.size()]
	# Re-pick next tick: drop the running order if it no longer fits the pin.
	if orders.has(cell) and is_instance_valid(orders[cell]):
		orders[cell].cancel()
		orders.erase(cell)
	var pinned: String = forced[cell]
	return "auto" if pinned == "auto" else String(RecipeDefs.get_def(pinned).name)

## What a workstation is set to make (for the hover readout).
func recipe_label(cell: Vector2i) -> String:
	var pinned: String = forced.get(cell, "auto")
	return "auto" if pinned == "auto" else String(RecipeDefs.get_def(pinned).name)

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
func _pick_recipe(station_id: String, cell: Vector2i) -> String:
	# A pinned recipe: make only that, when its inputs are in stock.
	var pinned: String = forced.get(cell, "auto")
	if pinned != "auto":
		var pdef := RecipeDefs.get_def(pinned)
		return pinned if _inputs_available(pdef.inputs) else ""
	# Auto: the first station recipe with inputs and room to stock.
	for id: String in RecipeDefs.ORDER:
		var def := RecipeDefs.get_def(id)
		if String(def.get("station", "")) != station_id:
			continue
		# Don't overproduce: skip recipes whose output is already stocked up.
		# Pool recipes (random output) count stock across the whole pool.
		var stocked := 0
		if def.has("output_pool"):
			for oid: String in def.output_pool:
				stocked += _count_free(oid)
		else:
			stocked = _count_free(def.output)
		if stocked >= int(def.get("max_stock", 999)):
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
