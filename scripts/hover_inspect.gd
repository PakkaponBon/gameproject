extends Node
## Feeds the HUD inspect line: a plain-language description of whatever
## the cursor is over. Reading the world beats guessing at squares.

@onready var main: Node2D = get_parent()
@onready var input_ctrl: PlayerInput = main.get_node("PlayerInput")

func _process(_delta: float) -> void:
	if input_ctrl.mode != PlayerInput.Mode.COMMAND:
		main.hud.set_inspect("")
		return
	var cell := input_ctrl.mouse_cell()
	main.hud.set_inspect(_describe(cell) if WorldGrid.in_bounds(cell) else "")

func _describe(cell: Vector2i) -> String:
	var parts: Array[String] = []
	var pawn: Pawn = main.pawn_at(cell)
	if pawn:
		parts.append("%s — %s" % [pawn.name, pawn.activity_text()])
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider.cell == cell:
			var who := "Warband boss" if raider.is_boss else "Bandit"
			if raider.faction_id != "":
				who += " (%s)" % FactionDefs.get_def(raider.faction_id).name
			parts.append(who)
	for node in get_tree().get_nodes_in_group("merchants"):
		if (node as Merchant).cell == cell:
			parts.append("Traveling merchant — click to trade")
	for node in get_tree().get_nodes_in_group("allies"):
		if (node as Ally).cell == cell:
			parts.append("Allied warrior")
	if WorldGrid.buildings.has(cell):
		var id: String = WorldGrid.buildings[cell]
		var text: String = BuildingDefs.get_def(id).name
		if WorldGrid.building_hp.has(cell):
			text += " (%d hp)" % int(WorldGrid.building_hp[cell])
		parts.append(text)
	if main.blueprints.has(cell):
		parts.append("Blueprint: %s (awaiting materials/build)" \
				% BuildingDefs.get_def(main.blueprints[cell].building_id).name)
	if main.decon_orders.has(cell):
		parts.append("Marked for deconstruction")
	for node in get_tree().get_nodes_in_group("crops"):
		var crop := node as Crop
		if crop.cell == cell:
			var pct := int(100.0 * minf(float(crop.growth_ticks) / float(crop.grow_ticks_total), 1.0))
			parts.append("%s — %d%% grown" % [CropDefs.get_def(crop.crop_id).name, pct])
	for node in get_tree().get_nodes_in_group("trees"):
		if (node as TreeEntity).cell == cell:
			parts.append("Tree")
	for node in get_tree().get_nodes_in_group("ore_nodes"):
		var ore := node as OreNode
		if ore.cell == cell:
			parts.append("%s deposit" % ResourceDefs.get_def(ore.resource_id).name)
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.cell == cell and not (item.get_parent() is Pawn):
			parts.append(ResourceDefs.get_def(item.resource_id).name)
	for node in get_tree().get_nodes_in_group("food"):
		if (node as FoodItem).cell == cell:
			parts.append("Food")
	for node in get_tree().get_nodes_in_group("graves"):
		if (node as Grave).cell == cell:
			parts.append("A grave")
	if WorldGrid.stockpile_cells.has(cell):
		parts.append("[stockpile]")
	if WorldGrid.fields.has(cell):
		parts.append("[%s field]" % CropDefs.get_def(WorldGrid.fields[cell]).name)
	if WorldGrid.safety_cells.has(cell):
		parts.append("[safety zone]")
	return " · ".join(parts)
