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
	var trap_uses: Array = []
	for cell: Vector2i in WorldGrid.traps:
		trap_uses.append({"cell": _v(cell), "uses": WorldGrid.traps[cell]})
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
		var item := node as FoodItem
		food.append({"cell": _v(item.cell), "kind": item.kind})
	var graves: Array = []
	for node in tree.get_nodes_in_group("graves"):
		graves.append(_v((node as Grave).cell))
	var bushes: Array = []
	for node in tree.get_nodes_in_group("bushes"):
		var bush := node as BerryBush
		bushes.append({"cell": _v(bush.cell), "regrow": bush.regrow_ticks})
	var livestock: Array = []
	for node in tree.get_nodes_in_group("livestock"):
		var animal := node as Livestock
		livestock.append({"cell": _v(animal.cell), "kind": animal.kind, "lay": animal.lay_timer})
	var raiders: Array = []
	for node in tree.get_nodes_in_group("raiders"):
		var raider := node as Raider
		raiders.append({
			"cell": _v(raider.cell),
			"hp": raider.hp,
			"boss": raider.is_boss,
			"looter": raider.is_looter,
			"beast": raider.is_beast,
			"elite": raider.is_elite,
			"loot": raider.carrying_loot,
			"faction": raider.faction_id,
			"atk_cd": raider.attack_cooldown,
			"move_cd": raider.move_cooldown,
		})
	# These three iterate dicts that can briefly hold a freed instance
	# (an order/blueprint queue_free()d before its keeper's next prune
	# tick). Read UNTYPED and validate first — a typed `var x: T = freed`
	# throws "invalid previously freed instance" on the assignment itself,
	# before any is_instance_valid guard can run.
	var blueprints: Array = []
	for cell: Vector2i in main.blueprints:
		var bp = main.blueprints[cell]
		if not is_instance_valid(bp):
			continue
		blueprints.append({
			"cell": _v(cell),
			"id": bp.building_id,
			"delivered": bp.delivered,
			"work": bp.build_job.work_ticks if bp.build_job else -1,
		})
	var decon: Array = []
	for cell: Vector2i in main.decon_orders:
		var order = main.decon_orders[cell]
		if not is_instance_valid(order):
			continue
		decon.append({"cell": _v(cell), "work": order.job.work_ticks})
	var craft_orders: Array = []
	for cell: Vector2i in main.forge_keeper.orders:
		var order = main.forge_keeper.orders[cell]
		if not is_instance_valid(order):
			continue  # finished between keeper prune ticks
		craft_orders.append({
			"cell": _v(cell),
			"recipe": order.recipe_id,
			"delivered": order.delivered,
			"work": order.craft_job.work_ticks if order.craft_job else -1,
		})
	var forced_recipes: Array = []
	for cell: Vector2i in main.forge_keeper.forced:
		forced_recipes.append({"cell": _v(cell), "recipe": main.forge_keeper.forced[cell]})
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
		"weather": WeatherDirector.current,
		"raid_ticks": main.raid_director.ticks_until_raid,
		"raid_count": main.raid_director.raid_count,
		"realm": FactionManager.serialize(),
		"building_hp": damaged,
		"trap_uses": trap_uses,
		"ground_seed": main.spawner.ground_seed,
		"buildings": built,
		"stockpiles": WorldGrid.stockpile_cells.keys().map(_v),
		"safety": WorldGrid.safety_cells.keys().map(_v),
		"trees": trees,
		"items": loose_items,
		"ore_nodes": ore_nodes,
		"food": food,
		"graves": graves,
		"bushes": bushes,
		"livestock": livestock,
		"raiders": raiders,
		"blueprints": blueprints,
		"decon_orders": decon,
		"craft_orders": craft_orders,
		"forced_recipes": forced_recipes,
		"fields": field_zones,
		"crops": crops,
		"chronicle": main.chronicle_director.entries,
		"tutorial_step": main.tutorial.step,
		"tutorial_done": main.tutorial.finished,
		"siege": {"phase": main.long_night.phase, "wave": main.long_night.wave_index,
				"timer": main.long_night.timer},
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
		"warmth": pawn.needs.warmth,
		"joy": pawn.needs.joy,
		"bonds": pawn.social.bonds,
		"on_break": pawn.needs.on_break,
		"sleeping": pawn.survival.sleeping,
		"bed": _v(pawn.survival.bed_cell),
		"hp": pawn.combat.hp,
		"atk_cd": pawn.combat.attack_cooldown,
		"weapon": pawn.combat.weapon_id,
		"armor": pawn.combat.armor_id,
		"ammo": pawn.combat.ammo,
		"relic": pawn.combat.relic_id,
		"relic_cd": pawn.combat.relic_cooldown,
		"carrying_herb": pawn.work.carrying_herb,
		"skills": pawn.skills.xp,
		"traits": pawn.traits,
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
