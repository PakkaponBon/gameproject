class_name SaveCollector
extends RefCounted
## Serializes the live session into the save dictionary. The applying half
## (rebuild-on-load) lives in the SaveManager autoload.

static func collect(main: Node2D, version: int) -> Dictionary:
	var tree := main.get_tree()
	var built: Array = []
	for cell: Vector2i in WorldGrid.buildings:
		built.append({"cell": _v(cell), "id": WorldGrid.buildings[cell]})
	var damaged: Array = []
	for cell: Vector2i in WorldGrid.building_hp:
		damaged.append({"cell": _v(cell), "hp": WorldGrid.building_hp[cell]})
	var trees: Array = []
	for node in tree.get_nodes_in_group("trees"):
		var t := node as TreeEntity
		trees.append({"cell": _v(t.cell), "work": t.job.work_ticks})
	var loose_items: Array = []
	for node in tree.get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.get_parent() is Pawn:
			continue  # carried items are saved with their pawn
		loose_items.append({"cell": _v(item.cell), "id": item.resource_id})
	var ore_nodes: Array = []
	for node in tree.get_nodes_in_group("ore_nodes"):
		var ore := node as OreNode
		ore_nodes.append({"cell": _v(ore.cell), "id": ore.resource_id, "work": ore.job.work_ticks})
	var food: Array = []
	for node in tree.get_nodes_in_group("food"):
		food.append(_v((node as FoodItem).cell))
	var graves: Array = []
	for node in tree.get_nodes_in_group("graves"):
		graves.append(_v((node as Grave).cell))
	var raiders: Array = []
	for node in tree.get_nodes_in_group("raiders"):
		var raider := node as Raider
		raiders.append({
			"cell": _v(raider.cell),
			"hp": raider.hp,
			"atk_cd": raider.attack_cooldown,
			"move_cd": raider.move_cooldown,
		})
	var blueprints: Array = []
	for cell: Vector2i in main.blueprints:
		var bp: Blueprint = main.blueprints[cell]
		blueprints.append({
			"cell": _v(cell),
			"id": bp.building_id,
			"delivered": bp.delivered,
			"work": bp.build_job.work_ticks if bp.build_job else -1,
		})
	var decon: Array = []
	for cell: Vector2i in main.decon_orders:
		decon.append({"cell": _v(cell), "work": main.decon_orders[cell].job.work_ticks})
	var craft_orders: Array = []
	for cell: Vector2i in main.forge_keeper.orders:
		var order: CraftOrder = main.forge_keeper.orders[cell]
		if not is_instance_valid(order):
			continue  # finished between keeper prune ticks
		craft_orders.append({
			"cell": _v(cell),
			"recipe": order.recipe_id,
			"delivered": order.delivered,
			"work": order.craft_job.work_ticks if order.craft_job else -1,
		})
	var field_zones: Array = []
	for cell: Vector2i in WorldGrid.fields:
		field_zones.append({"cell": _v(cell), "crop": WorldGrid.fields[cell]})
	var crops: Array = []
	for node in tree.get_nodes_in_group("crops"):
		var crop := node as Crop
		crops.append({"cell": _v(crop.cell), "id": crop.crop_id, "growth": crop.growth_ticks})
	var camera: Camera2D = main.get_node("Camera")
	return {
		"version": version,
		"clock_ticks": GameClock.ticks,
		"raid_ticks": main.raid_director.ticks_until_raid,
		"raid_count": main.raid_director.raid_count,
		"building_hp": damaged,
		"ground_seed": main.spawner.ground_seed,
		"buildings": built,
		"stockpiles": WorldGrid.stockpile_cells.keys().map(_v),
		"safety": WorldGrid.safety_cells.keys().map(_v),
		"trees": trees,
		"items": loose_items,
		"ore_nodes": ore_nodes,
		"food": food,
		"graves": graves,
		"raiders": raiders,
		"blueprints": blueprints,
		"decon_orders": decon,
		"craft_orders": craft_orders,
		"fields": field_zones,
		"crops": crops,
		"pawns": main.pawns.map(_pawn_data),
		"selected": main.pawns.find(main.selected),
		"camera": {"pos": [camera.position.x, camera.position.y], "zoom": camera.zoom.x},
	}

static func _pawn_data(pawn: Pawn) -> Dictionary:
	var priorities := {}
	for type: int in pawn.work_priorities:
		priorities[str(type)] = pawn.work_priorities[type]
	return {
		"name": String(pawn.name),
		"cell": _v(pawn.cell),
		"target": _v(pawn.target_cell),
		"hunger": pawn.needs.hunger,
		"rest": pawn.needs.rest,
		"mood": pawn.needs.mood,
		"on_break": pawn.needs.on_break,
		"sleeping": pawn.survival.sleeping,
		"bed": _v(pawn.survival.bed_cell),
		"hp": pawn.combat.hp,
		"atk_cd": pawn.combat.attack_cooldown,
		"weapon": pawn.combat.weapon_id,
		"skills": pawn.skills.xp,
		"wander_cd": pawn.survival.wander_cooldown,
		"collapsed": pawn.collapsed,
		"drafted": pawn.drafted,
		"attack_cell": _v(pawn.combat.attack_target.cell) if is_instance_valid(pawn.combat.attack_target) else [],
		"carrying_food": pawn.work.carrying_food,
		"carrying_id": pawn.work.carrying.resource_id if pawn.work.carrying else "",
		"priorities": priorities,
		"job_cell": _v(pawn.work.job.cell) if pawn.work.job else [],
		"job_type": int(pawn.work.job.type) if pawn.work.job else -1,
		"job_res": pawn.work.job.resource_id if pawn.work.job else "",
		"reserved_dest": _v(pawn.work.reserved_dest),
		"food_cell": _v(pawn.survival.food_target.cell) if pawn.survival.food_target else [],
		"eat_ticks": pawn.survival.eat_ticks_left,
	}

static func _v(v: Vector2i) -> Array:
	return [v.x, v.y]
