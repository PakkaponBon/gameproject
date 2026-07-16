extends Node2D
## The World scene: composes the systems and exposes the world API.
## Input lives in PlayerInput; ambient UI in HudController; per-villager
## UI in VillagerPanel; saving in the SaveManager autoload.

const SOURCE_ID := 0
const BLUEPRINT_SCENE := preload("res://scenes/blueprint.tscn")
const DECON_SCENE := preload("res://scenes/deconstruct_order.tscn")

var pawns: Array[Pawn] = []
var selected: Pawn = null
var _last_raid_faction := "bandit"
var blueprints := {}  # cell -> Blueprint
var decon_orders := {}  # cell -> DeconstructOrder
var _lights := {}  # cell -> PointLight2D (workstation glow)

@onready var walls: TileMapLayer = $Walls
@onready var entities: Node2D = $Entities
@onready var spawner: WorldSpawner = $WorldSpawner
@onready var raid_director: RaidDirector = $RaidDirector
@onready var field_keeper: FieldKeeper = $FieldKeeper
@onready var forge_keeper: ForgeKeeper = $ForgeKeeper
@onready var trade_director: TradeDirector = $TradeDirector
@onready var kitchen_keeper: KitchenKeeper = $KitchenKeeper
@onready var events_director: EventsDirector = $EventsDirector
@onready var trade_panel: TradePanel = $TradePanel
@onready var world_map: WorldMap = $WorldMap
@onready var story_panel: StoryPanel = $StoryPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var hud: HudController = $HUD
@onready var villager_panel: VillagerPanel = $VillagerPanel
@onready var priority_grid: PriorityGrid = $PriorityGrid
@onready var help_panel: HelpPanel = $HelpPanel
@onready var build_palette: BuildPalette = $BuildPalette
@onready var festival_director: FestivalDirector = $FestivalDirector
@onready var chronicle_director: ChronicleDirector = $ChronicleDirector
@onready var chronicle_panel: ChroniclePanel = $ChroniclePanel
@onready var choice_panel: ChoicePanel = $ChoicePanel
@onready var weather_director: WeatherDirector = $WeatherDirector

func _ready() -> void:
	UiTheme.apply_to_layers(self)  # children built their UI in their _ready
	raid_director.spawn_parent = entities
	field_keeper.spawn_parent = entities
	forge_keeper.spawn_parent = entities
	trade_director.spawn_parent = entities
	kitchen_keeper.spawn_parent = entities
	events_director.spawn_parent = entities
	raid_director.raid_started.connect(func(fname: String) -> void:
		hud.set_event("RAID — %s attacks!" % fname, Color(1.0, 0.4, 0.35))
		$Camera.shake(1.0, 5.0))
	raid_director.raid_started.connect(func(fname: String) -> void:
		_last_raid_faction = fname)
	raid_director.raid_warning.connect(func() -> void:
		hud.set_event("Scouts sighted beyond the treeline — a raid is coming. Draft [R] and man the walls.",
				Color(1.0, 0.75, 0.4)))
	raid_director.bell_rang.connect(func(world_pos: Vector2) -> void:
		hud.set_event("The alarm bell rings — raiders near!", Color(1.0, 0.55, 0.3), world_pos))
	raid_director.raid_ended.connect(func() -> void:
		FactionManager.add_renown(1)
		hud.set_event("The raid is beaten. Word of your village spreads.", Color(0.7, 0.95, 0.7))
		EventBus.chronicle_entry.emit("The %s raid was broken at the gates." % _last_raid_faction))
	pause_menu.save_requested.connect(func() -> void: SaveManager.save_game(SaveManager.MANUAL_SAVE_PATH))
	pause_menu.load_requested.connect(func(path: String) -> void: SaveManager.load_game(path))
	spawner.pawn_created.connect(_on_pawn_created)
	EventBus.building_built.connect(_on_building_built)
	EventBus.play_fx.connect(_on_play_fx)
	EventBus.building_deconstructed.connect(_on_building_deconstructed)
	EventBus.building_destroyed.connect(_on_building_destroyed)
	EventBus.merchant_arrived.connect(func() -> void:
		hud.set_event("A traveling merchant has arrived", Color(0.95, 0.85, 0.45)))
	EventBus.raider_stole.connect(func(world_pos: Vector2) -> void:
		hud.set_event("A looter grabbed your goods — stop him before he escapes!",
				Color(1.0, 0.6, 0.3), world_pos))
	SaveManager.main = self
	FactionManager.main = self
	FactionManager.announced.connect(hud.set_event)
	FactionManager.realm_ruled.connect(_on_realm_ruled)
	if SaveManager.pending_load.is_empty():
		_new_game()
	else:
		SaveManager.apply_pending_load()
	spawner.spawn_critters()
	if selected == null:
		_select_first_alive()
	$PlayerInput._update_mode_label()

func _new_game() -> void:
	# Autoloads survive scene changes; a fresh game starts from zero.
	WorldGrid.reset()
	JobManager.reset()
	FactionManager.reset()
	GameClock.ticks = 0
	GameClock.set_speed(1.0)
	GameClock.set_sim_paused(false)
	spawner.new_game()
	story_panel.show_pages([
		{"title": "VHAL BURNED", "body":
			"The city of Vhal stood a thousand years.\n"
			+ "It took one night to fall.\n\n"
			+ "The Ashen Legion came with fire,\n"
			+ "and the bells rang until they melted."},
		{"title": "THE ROAD OUT", "body":
			"Three of you slipped through the smoke —\n"
			+ "a wagon, tools, seed, and each other.\n\n"
			+ "Everyone carries something from that night.\n"
			+ "None of it as heavy as what they left."},
		{"title": "THE MEADOW", "body":
			"Beyond the hills: a quiet meadow.\n"
			+ "Wood, stone, water.\n\n"
			+ "A place to build. A place to endure.\n"
			+ "A place to remember."},
		{"title": "ONE DAY", "body":
			"Grow food. Raise walls. Keep the hearth warm.\n"
			+ "Five powers surround you — win them or break them.\n\n"
			+ "And when you are strong enough... answer Vhal.\n\n"
			+ "(Press H anytime for the controls.)"},
	])

# --- world API (called by PlayerInput / SaveManager / FactionManager) -------

func handle_command_click(cell: Vector2i) -> void:
	var clicked := pawn_at(cell)
	var raider := _raider_at(cell)
	var merchant := _merchant_at(cell)
	if clicked:
		select(clicked)
	elif merchant:
		trade_panel.open(merchant)
	elif raider and selected and selected.drafted:
		selected.attack(raider)
	elif selected:
		selected.move_to(cell)

func select(pawn: Pawn) -> void:
	if selected and is_instance_valid(selected):
		selected.set_selected(false)
	selected = pawn
	selected.set_selected(true)
	EventBus.play_sfx.emit("click")
	villager_panel.show_pawn(selected)

## Roster click: select AND look (Phase 14: one click does both).
func select_or_focus(pawn: Pawn) -> void:
	select(pawn)
	$Camera.position = pawn.position

## Save/load: restore the selection by index into the pawns array.
func select_pawn(index: int) -> void:
	if index >= 0 and index < pawns.size():
		select(pawns[index])

func cycle_selected_priority(type: Job.Type) -> void:
	if selected == null or selected.dead:
		return
	selected.cycle_priority(type)
	villager_panel.refresh()

func toggle_draft_selected() -> void:
	if selected and not selected.dead:
		selected.set_drafted(not selected.drafted)
		villager_panel.refresh()

func pawn_at(cell: Vector2i) -> Pawn:
	for pawn in pawns:
		if pawn.cell == cell:
			return pawn
	return null

## Instantly realize a finished (or loaded) building at a cell.
func place_building(cell: Vector2i, id: String) -> void:
	WorldGrid.register_building(cell, id)
	var def: Dictionary = BuildingDefs.get_def(id)
	walls.set_cell(cell, SOURCE_ID, def.tile)
	# Fire-warmed workstations, hearths, and braziers glow at night.
	if def.get("workstation", false) or def.get("kitchen", false) or def.get("light", false):
		var light := PointLight2D.new()
		light.texture = preload("res://assets/light.png")
		light.position = WorldGrid.cell_to_world(cell)
		light.color = Color(1.0, 0.7, 0.4)
		light.energy = 0.9
		light.texture_scale = 1.4
		entities.add_child(light)
		_lights[cell] = light

func _remove_light(cell: Vector2i) -> void:
	if _lights.has(cell):
		_lights[cell].queue_free()
		_lights.erase(cell)

func place_blueprint(cell: Vector2i, id: String) -> void:
	if not WorldGrid.in_bounds(cell) or WorldGrid.buildings.has(cell) \
			or blueprints.has(cell) or pawn_at(cell):
		return
	var need := int(BuildingDefs.get_def(id).get("renown_req", 0))
	if FactionManager.renown < need:
		hud.set_event("%s needs renown %d (beat raids, resolve factions)." \
				% [BuildingDefs.get_def(id).name, need])
		return
	var bp: Blueprint = BLUEPRINT_SCENE.instantiate()
	bp.building_id = id
	bp.position = WorldGrid.cell_to_world(cell)
	entities.add_child(bp)
	blueprints[cell] = bp

## RMB: cancel a blueprint, toggle a deconstruct order, or mark a building.
## While dragging, never un-mark — motion events would flicker it.
func remove_at(cell: Vector2i, dragging := false) -> void:
	if blueprints.has(cell):
		blueprints[cell].cancel()
		blueprints.erase(cell)
	elif decon_orders.has(cell):
		if not dragging:
			decon_orders[cell].cancel()
			decon_orders.erase(cell)
	elif WorldGrid.buildings.has(cell):
		mark_deconstruct(cell)

func mark_deconstruct(cell: Vector2i) -> void:
	var order: DeconstructOrder = DECON_SCENE.instantiate()
	order.position = WorldGrid.cell_to_world(cell)
	entities.add_child(order)
	decon_orders[cell] = order

## Expedition glue: villagers leave the map as data and come home changed.
func remove_pawn_for_expedition(pawn: Pawn) -> void:
	pawn.prepare_depart()
	pawns.erase(pawn)
	if selected == pawn:
		selected = null
		if pawns.is_empty():
			villager_panel.show_pawn(null)
		else:
			_select_first_alive()
	pawn.queue_free()

func return_expedition_member(pdata: Dictionary) -> void:
	var cell := _free_cell_near(WorldGrid.MAP_SIZE / 2)
	var pawn := spawner.create_pawn(cell, pdata.name,
			{Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1})
	pawn.traits = pdata.traits
	for skill_id: String in pdata.skills:
		pawn.skills.xp[skill_id] = float(pdata.skills[skill_id])
	if String(pdata.weapon) != "":
		pawn.combat.equip(pdata.weapon)
	if String(pdata.get("armor", "")) != "":
		pawn.combat.equip_armor(String(pdata.armor))
	pawn.combat.ammo = int(pdata.ammo)
	pawn.combat.relic_id = String(pdata.relic)
	pawn.combat.hp = maxf(float(pdata.hp) * 0.8, 30.0)  # battle-worn
	if selected == null:
		select(pawn)

func mourn_expedition_loss() -> void:
	spawner.spawn_entity(spawner.GRAVE_SCENE, _free_cell_near(WorldGrid.MAP_SIZE / 2))
	for pawn in pawns:
		pawn.needs.mourn()

# --- internals ---------------------------------------------------------------

func _select_first_alive() -> void:
	for pawn in pawns:
		if not pawn.dead:
			select(pawn)
			return
	if not pawns.is_empty():
		select(pawns[0])

func _free_cell_near(center: Vector2i) -> Vector2i:
	for radius in 6:
		var cell := center + Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
		if WorldGrid.in_bounds(cell) and not WorldGrid.is_wall(cell):
			return cell
	return center

func _raider_at(cell: Vector2i) -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider.cell == cell:
			return raider
	return null

func _merchant_at(cell: Vector2i) -> Merchant:
	for node in get_tree().get_nodes_in_group("merchants"):
		var merchant := node as Merchant
		if merchant.cell == cell:
			return merchant
	return null

func _on_pawn_created(pawn: Pawn) -> void:
	pawn.stats_changed.connect(_on_pawn_stats_changed.bind(pawn))
	pawn.died.connect(_on_pawn_died.bind(pawn))
	pawns.append(pawn)

func _on_pawn_stats_changed(pawn: Pawn) -> void:
	if pawn == selected:
		villager_panel.refresh()

func _on_pawn_died(pawn: Pawn) -> void:
	Fx.ash_mark(entities, pawn.position)  # tone rule: ash, not blood
	spawner.spawn_entity(spawner.GRAVE_SCENE, pawn.cell)
	if pawn.combat.weapon_id != "":
		spawner.drop_resource(pawn.cell, pawn.combat.weapon_id, 1)  # gear outlives its owner
	if pawn.combat.armor_id != "":
		spawner.drop_resource(pawn.cell, pawn.combat.armor_id, 1)
	pawns.erase(pawn)
	for other in pawns:
		# Loss is real: colony-wide mood hit, and friends grieve deeper.
		if other.social.is_friend(String(pawn.name)):
			other.needs.grieve()
			EventBus.chronicle_entry.emit("%s grieves for %s." % [other.name, pawn.name])
		else:
			other.needs.mourn()
	hud.set_event("%s has died." % pawn.name, Color(1.0, 0.4, 0.35), pawn.position)
	EventBus.chronicle_entry.emit("%s was laid to rest beneath the meadow." % pawn.name)
	if pawns.is_empty():
		selected = null
		villager_panel.show_pawn(null)
		story_panel.show_ending("THE HEARTH GOES COLD",
				"The last of you is gone. The meadow keeps the graves,\n"
				+ "and the wind keeps the rest.\n\n"
				+ "Somewhere, the Ashen Legion never learns your names.")
	elif selected == pawn:
		_select_first_alive()

const FX_COLORS := {
	Job.Type.CHOP: Color(0.6, 0.45, 0.28),  # wood chips
	Job.Type.MINE: Color(0.62, 0.62, 0.68),  # stone dust
	Job.Type.PLANT: Color(0.42, 0.3, 0.18),  # soil puff
	Job.Type.HARVEST: Color(0.5, 0.7, 0.35),
	Job.Type.BUILD: Color(0.7, 0.7, 0.72),
	Job.Type.DECONSTRUCT: Color(0.7, 0.7, 0.72),
}

func _on_play_fx(job_type: int, cell: Vector2i) -> void:
	if FX_COLORS.has(job_type):
		Fx.burst(entities, WorldGrid.cell_to_world(cell), FX_COLORS[job_type])

func _on_building_built(cell: Vector2i, building_id: String) -> void:
	blueprints.erase(cell)
	place_building(cell, building_id)
	# Fresh build only (load restores saved animals): a new coop comes
	# stocked with hens. Load uses place_building directly, so no dupes.
	var def: Dictionary = BuildingDefs.get_def(building_id)
	if def.has("livestock"):
		for i in int(def.get("livestock_count", 2)):
			spawner.spawn_livestock(_free_cell_near(cell), def.livestock)
		hud.set_event("The %s is stocked — its animals settle in." % def.name, Color(0.9, 0.85, 0.6))
		EventBus.chronicle_entry.emit("A %s was raised, and its animals came home." % def.name)

## Smashed by enemies (or a trap spending itself): gone, no refund.
func _on_building_destroyed(cell: Vector2i) -> void:
	var bname: String = BuildingDefs.get_def(WorldGrid.buildings[cell]).name \
			if WorldGrid.buildings.has(cell) else "building"
	if decon_orders.has(cell):
		decon_orders[cell].cancel()
		decon_orders.erase(cell)
	WorldGrid.remove_building(cell)
	walls.erase_cell(cell)
	_remove_light(cell)
	hud.set_event("The %s is destroyed!" % bname, Color(1.0, 0.6, 0.3), WorldGrid.cell_to_world(cell))

func _on_building_deconstructed(cell: Vector2i) -> void:
	decon_orders.erase(cell)
	var refund: Dictionary = BuildingDefs.get_def(WorldGrid.buildings[cell]).refund
	WorldGrid.remove_building(cell)
	walls.erase_cell(cell)
	_remove_light(cell)
	for id: String in refund:
		spawner.drop_resource(cell, id, int(refund[id]))

func _on_realm_ruled() -> void:
	EventBus.chronicle_entry.emit("The last banner bowed. The realm is ours.")
	story_panel.show_story("RULER OF THE REALM",
			"Every banner in the realm bows or burns.\n\n"
			+ "From three survivors and a wagon to this: the roads are yours,\n"
			+ "the tributes flow, and the ones who lit the fire are answered.\n\n"
			+ "The hearth you built still burns. Warmer now, for all of it.")
