class_name EventsDirector
extends Node
## Small morning events: frost snaps and refugee arrivals. Tribute
## ultimatums already live in FactionManager. Scene-local to Main.

const FROST_CHANCE := 0.08
const REFUGEE_BASE_CHANCE := 0.05
const REFUGEE_RENOWN_BONUS := 0.02  # per renown point
const VILLAGER_CAP := 15  # per GAME_DESIGN

var spawn_parent: Node2D = null  # assigned by Main

@onready var main: Node2D = get_parent()

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)

const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const BARD_CHANCE := 0.07
const STAR_CHANCE := 0.04
const DILEMMA_CHANCE := 0.3  # roughly one decision knocking every few days
const OATH_CHANCE := 0.08  # a friendly faction may propose kinship
const OMEN_CHANCE := 0.06
const HARVEST_CHANCE := 0.05

func _on_day_started(_day: int) -> void:
	if main.raid_director.siege_active:
		return  # the Long Night owns the field — no frost, wolves, or dilemmas
	if GameClock.season_index() != 3 and randf() < FROST_CHANCE:
		_frost_snap()
	if GameClock.season_index() == 3 and not Balance.peaceful() \
			and randf() < Balance.WOLF_PACK_CHANCE \
			and get_tree().get_nodes_in_group("raiders").is_empty():
		_wolf_pack()
	var refugee_chance := REFUGEE_BASE_CHANCE + REFUGEE_RENOWN_BONUS * FactionManager.renown
	if main.pawns.size() < VILLAGER_CAP and randf() < minf(refugee_chance, 0.3):
		_refugee_arrives()
	if randf() < BARD_CHANCE:
		_bard_visits()
	if randf() < STAR_CHANCE:
		_star_falls()
	if randf() < DILEMMA_CHANCE and get_tree().get_nodes_in_group("raiders").is_empty():
		_roll_dilemma()
	elif randf() < OATH_CHANCE and get_tree().get_nodes_in_group("raiders").is_empty():
		_oath_offer()
	if randf() < OMEN_CHANCE:
		_an_omen()
	if randf() < HARVEST_CHANCE:
		_fine_harvest()
	_replenish_game()

## Ambient colour — a shared mood swing the elders read in the sky.
func _an_omen() -> void:
	var good := randf() < 0.5
	var delta := 6.0 if good else -5.0
	for pawn: Pawn in main.pawns:
		pawn.needs.mood = clampf(pawn.needs.mood + delta, 0.0, 100.0)
	main.hud.set_event("A red dawn — the elders call it %s." \
			% ("a good omen" if good else "an ill omen"),
			Color(0.9, 0.8, 0.6) if good else Color(0.72, 0.62, 0.72))

## A windfall in the fields: a small basket of food appears near home.
func _fine_harvest() -> void:
	var center: Vector2i = WorldGrid.MAP_SIZE / 2
	for i in 4:
		var food: FoodItem = FOOD_SCENE.instantiate()
		food.position = WorldGrid.cell_to_world(center + Vector2i(randi_range(-3, 3), randi_range(-3, 3)))
		main.entities.add_child(food)
	main.hud.set_event("A fine day in the fields — the baskets come back full.", Color(0.7, 0.9, 0.6))

## S4 — oath of kinship: a friendly faction asks for a marriage bond.
## A real villager leaves for a permanent friendship. Tone: text, warm,
## brief — the wedding is told, never shown.
func _oath_offer() -> void:
	if main.pawns.size() < 4:
		return  # can't spare a soul from a skeleton crew
	var suitors: Array[String] = []
	for id: String in FactionManager.factions:
		var f: Dictionary = FactionManager.factions[id]
		if f.resolved == "" and float(f.attitude) >= 50.0 and not bool(f.get("oath", false)):
			suitors.append(id)
	if suitors.is_empty():
		return
	var id: String = suitors.pick_random()
	var candidates: Array = main.pawns.filter(func(p: Pawn) -> bool:
		return not p.drafted and not p.collapsed and not p.dead)
	if candidates.is_empty():
		return
	var pawn: Pawn = candidates.pick_random()
	var def := FactionDefs.get_def(id)
	var leader := String(def.get("leader", "their chief"))
	var fname := String(def.name)
	var accept := func() -> void:
		main.hud.set_event("%s departs with the %s escort, head high. The bond holds while the village stands." \
				% [pawn.name, fname], Color(0.9, 0.8, 0.6))
		EventBus.chronicle_entry.emit("%s wed into %s. The village keeps their name like a candle in a window." \
				% [pawn.name, fname])
		FactionManager.swear_oath(id)
		main.remove_pawn_for_expedition(pawn)  # leaves cleanly, claims released
	var decline := func() -> void:
		FactionManager.decline_oath(id)
	main.choice_panel.open("AN OATH OF KINSHIP",
			"%s of %s proposes a marriage bond, and names %s. The kinship would hold their friendship for good — but %s would leave the meadow, for a hall far from your hearth." \
					% [leader, fname, pawn.name, pawn.name],
			"Let %s go — permanent friendship" % pawn.name,
			"Politely decline (they will take it hard)",
			accept, decline)

## Keep huntable game topped up: ambient life stays alive AND meat stays a
## renewable trickle, so hunting never exterminates the meadow. Some of
## what wanders in is a boar — more meat, but it bites.
func _replenish_game() -> void:
	var count := get_tree().get_nodes_in_group("game").size()
	while count < Balance.CRITTER_TARGET:
		main.spawner.spawn_one_critter(false, randf() < Balance.BOAR_CHANCE)
		count += 1

## Winter's own raid: an ash-wolf pack breaks from the treeline.
func _wolf_pack() -> void:
	main.raid_director.spawn_beast_pack(randi_range(3, 4))
	main.hud.set_event("Ash-wolves! A pack breaks from the treeline — get everyone inside.",
			Color(0.75, 0.8, 0.95))
	EventBus.chronicle_entry.emit("A wolf winter. The pack came down with the cold.")

## Decisions at the gate: pause, two buttons, consequences. This is the
## beat the sim can't generate on its own.
func _roll_dilemma() -> void:
	var dilemmas: Array[Callable] = [_wounded_stranger, _deserter, _merchants_map,
			_strange_lights, _the_fever, _the_feud, _buried_cache, _the_scholar]
	(dilemmas.pick_random() as Callable).call()

func _the_fever() -> void:
	var treat := func() -> void:
		if not _consume("herb", 2):
			main.hud.set_event("No herbs to spare — the fever runs its course.", Color(0.8, 0.7, 0.6))
			_fever_spreads()
			return
		main.hud.set_event("The herb-stores answer the fever. It breaks by morning.", Color(0.7, 0.95, 0.7))
		EventBus.chronicle_entry.emit("A fever came in the night. The herb-stores turned it back.")
	var ride := func() -> void:
		_fever_spreads()
		EventBus.chronicle_entry.emit("A fever swept the village. They bore it, and most rose again.")
	main.choice_panel.open("A FEVER IN THE VILLAGE",
			"Two villagers wake burning, and it will spread. Healing herbs would break it — "
			+ "or you let it run its course and hope.",
			"Treat it (2 herbs)", "Ride it out (they'll suffer)", treat, ride)

func _fever_spreads() -> void:
	for pawn: Pawn in main.pawns:
		pawn.combat.drain(6.0)  # weakness, not wounds — no gore
		pawn.needs.mood = maxf(pawn.needs.mood - 6.0, 0.0)

func _the_feud() -> void:
	if main.pawns.size() < 2:
		return
	var two: Array = main.pawns.duplicate()
	two.shuffle()
	var a: Pawn = two[0]
	var b: Pawn = two[1]
	var side := func() -> void:
		a.needs.mood = minf(a.needs.mood + 10.0, 100.0)
		b.needs.mood = maxf(b.needs.mood - 12.0, 0.0)
		main.hud.set_event("You side with %s. %s stews, but the matter's closed." % [a.name, b.name])
	var settle := func() -> void:
		a.needs.mood = maxf(a.needs.mood - 4.0, 0.0)
		b.needs.mood = maxf(b.needs.mood - 4.0, 0.0)
		main.hud.set_event("You let %s and %s settle it themselves." % [a.name, b.name])
		EventBus.chronicle_entry.emit("%s and %s came to blows, then to a wary peace." % [a.name, b.name])
	main.choice_panel.open("A FEUD",
			"%s and %s are at each other's throats over an old slight, and the village is taking sides. "
			% [a.name, b.name] + "They're waiting to see what you'll do.",
			"Side with %s" % a.name, "Let them settle it", side, settle)

func _buried_cache() -> void:
	var center: Vector2i = WorldGrid.MAP_SIZE / 2
	var keep := func() -> void:
		main.spawner.drop_resource(center, "iron_ingot", 2)
		main.spawner.drop_resource(center + Vector2i(1, 0), "stone", 3)
		main.hud.set_event("You pocket the cache. No one need know.", Color(0.9, 0.85, 0.5))
	var share := func() -> void:
		main.spawner.drop_resource(center, "stone", 3)
		for pawn: Pawn in main.pawns:
			pawn.needs.mood = minf(pawn.needs.mood + 6.0, 100.0)
		main.hud.set_event("You share the find. The village stands a little taller.", Color(0.7, 0.95, 0.7))
		EventBus.chronicle_entry.emit("A cache was found in the old foundations, and shared openly.")
	main.choice_panel.open("A CACHE IN THE FOUNDATIONS",
			"Digging a footing, a villager strikes a buried strongbox — iron and worked stone. "
			+ "Only the two of you saw it come up.",
			"Keep it quiet (more goods)", "Share it (spirits lift)", keep, share)

func _the_scholar() -> void:
	if main.pawns.is_empty():
		return
	var pawn: Pawn = main.pawns.pick_random()
	var teach := func() -> void:
		if not _consume_food(8):
			main.hud.set_event("You can't feed the scholar. She moves on down the road.")
			return
		var skill: String = ["melee", "archery"].pick_random()
		pawn.skills.gain(skill, 300.0)
		main.hud.set_event("%s studies with the scholar and sharpens their %s." % [pawn.name, skill],
				Color(0.7, 0.85, 0.95))
		EventBus.chronicle_entry.emit("A wandering scholar taught %s what the long road had taught her." % pawn.name)
	main.choice_panel.open("A WANDERING SCHOLAR",
			"A scholar of the old roads offers to teach, for a few good meals. "
			+ "%s has the look of someone eager to learn." % pawn.name,
			"Host her (8 food) — train %s" % pawn.name, "Send her on", teach, Callable())

func _wounded_stranger() -> void:
	var accept := func() -> void:
		var pawn := _spawn_newcomer()
		pawn.combat.hp = 40.0
		main.hud.set_event("%s is given a bed. Time will tell." % pawn.name)
		EventBus.chronicle_entry.emit("A wounded stranger, %s, was taken in." % pawn.name)
	var refuse := func() -> void:
		for pawn: Pawn in main.pawns:
			pawn.needs.mood = maxf(pawn.needs.mood - 4.0, 0.0)
		EventBus.chronicle_entry.emit("A stranger was turned from the gate. The wind carried her plea.")
	main.choice_panel.open("A STRANGER AT THE GATE",
			"A woman limps out of the treeline, arm bound in a bloodless rag. "
			+ "She asks for a roof and swears she can work once she mends.",
			"Take her in (a wounded mouth to feed)",
			"Turn her away (the village will feel it)", accept, refuse)

func _deserter() -> void:
	var accept := func() -> void:
		if not _consume_food(10):
			main.hud.set_event("The larder can't spare 10 food. He shrugs and walks on.")
			return
		var pawn := _spawn_newcomer()
		pawn.combat.equip("sword")
		pawn.skills.xp["melee"] = 400.0
		main.hud.set_event("%s hangs his old colors by the door." % pawn.name)
		EventBus.chronicle_entry.emit("%s, once a soldier of another banner, joined the village." % pawn.name)
	main.choice_panel.open("THE DESERTER",
			"A soldier in stripped colors waits at bow's reach. He is done with "
			+ "banners, he says — he will fight for a hearth and ten meals.",
			"Feed him (10 food) — gain an armed villager",
			"Send him down the road", accept, Callable())

func _merchants_map() -> void:
	var buy := func() -> void:
		if not _consume_items("wood", 5):
			main.hud.set_event("You can't spare the wood. The trader moves on.")
			return
		if randf() < 0.65:
			var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
			for id: String in ["wood", "wood", "stone", "stone", "iron_ore"]:
				main.spawner.drop_resource(cell, id, 1)
			main.hud.set_event("The map holds true — a cache lies in the wild.",
					Color(0.7, 0.9, 1.0), WorldGrid.cell_to_world(cell))
			EventBus.chronicle_entry.emit("A trader's map led to a buried war cache.")
		else:
			main.hud.set_event("The dig finds nothing but roots. The trader is long gone.")
			EventBus.chronicle_entry.emit("A trader's map led to nothing. Lesson kept.")
	main.choice_panel.open("THE MERCHANT'S MAP",
			"A trader offers a creased map — a supply cache from the war, buried "
			+ "half a day out. He wants 5 wood for it and won't say why he hasn't dug it up himself.",
			"Buy the map (5 wood)",
			"Keep your wood", buy, Callable())

func _strange_lights() -> void:
	var send := func() -> void:
		var pawn: Pawn = main.pawns.pick_random()
		pawn.skills.xp["melee"] += 150.0
		pawn.skills.xp["archery"] += 150.0
		if randf() < 0.35:
			pawn.take_damage(15.0)
			main.hud.set_event("%s returns pale and quiet — but sharper." % pawn.name)
		else:
			main.hud.set_event("%s returns at dawn, eyes bright, saying little." % pawn.name)
		EventBus.chronicle_entry.emit("%s followed the lights in the wood and came back changed." % pawn.name)
	main.choice_panel.open("LIGHTS IN THE WOOD",
			"Pale lights wander between the far pines, two nights running. "
			+ "Someone could go and look. Someone probably shouldn't.",
			"Send someone (they'll come back changed)",
			"Bar the doors at night", send, Callable())

func _spawn_newcomer() -> Pawn:
	var edge := Vector2i(randi() % WorldGrid.MAP_SIZE.x, 0)
	if WorldGrid.is_wall(edge):
		edge = WorldGrid.MAP_SIZE / 2
	var pawn: Pawn = main.spawner.create_pawn(edge, main.spawner.unused_name(),
			{Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1})
	var pool := TraitDefs.BACKSTORIES.duplicate()
	pawn.traits = [pool.pick_random()]
	return pawn

func _consume_items(id: String, count: int) -> bool:
	var found: Array[ResourceItem] = []
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			found.append(item)
			if found.size() >= count:
				break
	if found.size() < count:
		return false
	for item in found:
		item.queue_free()
	return true

func _consume_food(count: int) -> bool:
	var found: Array[FoodItem] = []
	for node in get_tree().get_nodes_in_group("food"):
		var item := node as FoodItem
		if not item.reserved:
			found.append(item)
			if found.size() >= count:
				break
	if found.size() < count:
		return false
	for item in found:
		item.queue_free()
	return true

func _bard_visits() -> void:
	for pawn: Pawn in main.pawns:
		pawn.needs.celebrate()
	main.hud.set_event("A wandering bard plays through the evening. Spirits lift.",
			Color(0.8, 0.7, 0.95))
	EventBus.chronicle_entry.emit("A bard sang of far places, and for one night the meadow felt bigger.")

## A relic falls from the sky somewhere wild — go claim it before winter
## buries it (or don't; it isn't going anywhere, but it feels urgent).
func _star_falls() -> void:
	var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
	if WorldGrid.is_wall(cell) or WorldGrid.items.has(cell):
		return  # the sky misses this year
	main.spawner.spawn_resource(cell, RelicDefs.ORDER.pick_random())
	main.hud.set_event("A star fell in the night — something glitters where it landed.",
			Color(0.7, 0.9, 1.0), WorldGrid.cell_to_world(cell))
	EventBus.chronicle_entry.emit("A star fell beyond the fields. The bold went looking.")

func _frost_snap() -> void:
	var killed := 0
	for node in get_tree().get_nodes_in_group("crops"):
		if randf() < 0.5:
			(node as Crop).kill()
			killed += 1
	if killed > 0:
		main.hud.set_event("An unseasonal frost kills %d crops!" % killed, Color(0.6, 0.8, 1.0))
		main.field_keeper.sync_all()  # replant the emptied cells

func _refugee_arrives() -> void:
	var edge := Vector2i(randi() % WorldGrid.MAP_SIZE.x, 0)
	if WorldGrid.is_wall(edge):
		edge = WorldGrid.MAP_SIZE / 2
	var pawn: Pawn = main.spawner.create_pawn(edge, main.spawner.unused_name(),
			{Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1})
	var pool := TraitDefs.BACKSTORIES.duplicate()
	pawn.traits = [pool.pick_random()]
	pawn.skills.xp["melee"] = float(randi_range(0, 200))
	pawn.skills.xp["archery"] = float(randi_range(0, 300))
	main.hud.set_event("%s heard of your village and asks to stay." % pawn.name,
			Color(0.7, 0.95, 0.7))
	EventBus.chronicle_entry.emit("%s arrived at the gate with nothing, and stayed." % pawn.name)
