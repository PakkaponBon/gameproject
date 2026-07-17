extends Node
## Autoload (Phase 6+): faction state, diplomacy, expeditions, victory.
## The world map is UI over this data — never a second simulated map.

signal factions_changed
signal announced(text: String)
signal realm_ruled
signal long_night_begins  # the four others resolved; the Legion comes

const GIFT_WOOD := 10
const LIKED_GIFT_BONUS := 25.0  # a leader's prized gift lands far harder
const TRIBUTE_WOOD := 15
const ENVOY_COOLDOWN_TICKS := 3000  # one envoy per faction per day
const DEMAND_CHANCE_PER_DAY := 0.2
const DEMAND_GRACE_TICKS := 3000  # a day to pay
const ALLIANCE_AT := 100.0
const REQUEST_CHANCE_PER_DAY := 0.25
const REQUEST_GRACE_TICKS := GameClock.TICKS_PER_DAY * 2
const WAR_CHANCE_PER_DAY := 0.15
const WAR_FLOOR := 5.0  # wars grind factions down but never finish one —
						# the killing blow (or the friendship) stays yours
const EXPEDITION_TICKS := 3000  # the party is away one day
const EXPEDITION_STRENGTH_HIT := 25.0  # site difficulty now lives in SiteDefs
const KILL_ATTRITION := 2.0  # faction strength lost per bandit slain

var factions := {}  # id -> {strength, attitude, resolved, envoy_ready, demand_deadline}
var expedition := {}  # {} when none; else target/return_tick/party/power
var request := {}  # {} or {id, resource, amount, deadline}: a faction's standing ask
var sites := {}  # wild site id -> tick when it's worth raiding again
var victory_shown := false
var long_night := false  # Act III siege has been triggered (persists through it)
var renown := 0  # village fame: unlocks buildings, attracts refugees
var main: Node2D = null  # current Main scene; re-registers itself each load

func _ready() -> void:
	reset()
	GameClock.ticked.connect(_on_tick)
	GameClock.day_started.connect(_on_day_started)

func reset() -> void:
	factions.clear()
	for id: String in FactionDefs.ORDER:
		var def := FactionDefs.get_def(id)
		factions[id] = {
			"strength": float(def.strength),
			"attitude": float(def.attitude),
			"resolved": "",  # "" | "allied" | "destroyed"
			"envoy_ready": 0,
			"demand_deadline": 0,
		}
	expedition = {}
	request = {}
	sites.clear()
	victory_shown = false
	long_night = false
	renown = 0
	factions_changed.emit()

func add_renown(amount: int) -> void:
	renown += amount
	factions_changed.emit()

func serialize() -> Dictionary:
	return {"factions": factions, "expedition": expedition, "request": request,
			"sites": sites, "victory_shown": victory_shown, "long_night": long_night,
			"renown": renown, "difficulty": Balance.mode}

func deserialize(data: Dictionary) -> void:
	factions = data.factions
	expedition = data.expedition
	request = data.get("request", {})
	sites = data.get("sites", {})
	long_night = bool(data.get("long_night", false))
	victory_shown = bool(data.victory_shown)
	renown = int(data.renown)
	Balance.mode = String(data.difficulty)
	factions_changed.emit()

# --- diplomacy --------------------------------------------------------------

func send_gift(id: String) -> void:
	if _resolved(id):
		return
	# A standing request makes the gift land differently: their need, met.
	if not request.is_empty() and String(request.id) == id:
		if not _consume(String(request.resource), int(request.amount)):
			announced.emit("You lack the %d %s that %s asked for." \
					% [int(request.amount), String(request.resource), _fname(id)])
			return
		announced.emit("%s receives exactly what they needed. Word of it travels." % _fname(id))
		EventBus.chronicle_entry.emit("The village answered %s's call for %s." \
				% [_fname(id), String(request.resource)])
		request = {}
		add_renown(1)
		_shift_attitude(id, 30.0)
		return
	# The leader's prized gift, if we can spare it, beats a cart of wood.
	var def := FactionDefs.get_def(id)
	if def.has("likes") and _consume(String(def.likes), int(def.likes_count)):
		announced.emit("%s prizes such a gift above all. %s warms to the village." \
				% [String(def.leader), _fname(id)])
		EventBus.chronicle_entry.emit("A gift of %s went to %s. It was the right one." \
				% [ResourceDefs.get_def(String(def.likes)).name, String(def.leader)])
		_shift_attitude(id, LIKED_GIFT_BONUS)
		return
	if not _consume("wood", GIFT_WOOD):
		announced.emit("Not enough spare wood for a gift (%d needed)." % GIFT_WOOD)
		return
	var bonus: float = {"aggressive": 10.0, "honorable": 12.0, "greedy": 20.0}[_personality(id)]
	announced.emit("A gift is sent to %s." % _fname(id))
	_shift_attitude(id, bonus)

func send_envoy(id: String) -> void:
	if _resolved(id):
		return
	var f: Dictionary = factions[id]
	if GameClock.ticks < int(f.envoy_ready):
		announced.emit("Your envoy to %s needs time before returning." % _fname(id))
		return
	f.envoy_ready = GameClock.ticks + ENVOY_COOLDOWN_TICKS
	announced.emit("An envoy rides to %s of %s." % [_leader(id), _fname(id)])
	_shift_attitude(id, 6.0 if _personality(id) == "honorable" else 4.0)

func pay_tribute(id: String) -> void:
	var f: Dictionary = factions[id]
	if int(f.demand_deadline) == 0:
		return
	if not _consume("wood", TRIBUTE_WOOD):
		announced.emit("The stores can't cover the tribute (%d wood)." % TRIBUTE_WOOD)
		return
	f.demand_deadline = 0
	announced.emit("Tribute paid to %s. They are appeased — for now." % _fname(id))
	_shift_attitude(id, 10.0)

func demand_pending(id: String) -> bool:
	return int(factions[id].demand_deadline) > 0

## S4 — oath of kinship: a villager weds into the faction. Friendship
## gets a permanent floor and their warriors answer big raids like an
## ally's. The "oath" key rides inside the factions dict (saved as-is).
func swear_oath(id: String) -> void:
	var f: Dictionary = factions[id]
	f["oath"] = true
	announced.emit("The oath is sworn. %s will not forget the village." % _fname(id))
	_shift_attitude(id, 30.0)

func decline_oath(id: String) -> void:
	announced.emit("The offer, refused, stings %s's pride." % _fname(id))
	_shift_attitude(id, -5.0)

func has_oath(id: String) -> bool:
	return bool(factions[id].get("oath", false))

# --- raids ------------------------------------------------------------------

func pick_raid_faction(prefer_weak := false) -> String:
	var hostile: Array[String] = []
	for id: String in factions:
		if factions[id].resolved == "" and float(factions[id].attitude) < 0.0:
			hostile.append(id)
	if hostile.is_empty():
		return ""
	if prefer_weak:  # early game: the local bandits probe first
		hostile.sort_custom(func(a: String, b: String) -> bool:
			return float(factions[a].strength) < float(factions[b].strength))
		return hostile[0]
	return hostile.pick_random()

func raid_size(id: String) -> int:
	return clampi(2 + int(float(factions[id].strength) / 25.0), 2, 8)

func has_ally() -> bool:
	for id: String in factions:
		var f: Dictionary = factions[id]
		if f.resolved == "allied" or (bool(f.get("oath", false)) and f.resolved != "destroyed"):
			return true
	return false

func on_bandit_killed(id: String) -> void:
	if factions.has(id):
		damage_strength(id, KILL_ATTRITION)

func damage_strength(id: String, amount: float) -> void:
	var f: Dictionary = factions[id]
	f.strength = maxf(float(f.strength) - amount, 0.0)
	if float(f.strength) <= 0.0 and f.resolved == "":
		f.resolved = "destroyed"
		renown += 5
		announced.emit("%s is broken! Their stores are absorbed into the village." % _fname(id))
		EventBus.chronicle_entry.emit("%s is broken, and %s's banner burns with them." \
				% [_fname(id), _leader(id)])
		if is_instance_valid(main):
			var center: Vector2i = WorldGrid.MAP_SIZE / 2
			main.spawner.drop_resource(center, "wood", 8)
			main.spawner.drop_resource(center + Vector2i(2, 0), "stone", 5)
			main.spawner.drop_resource(center + Vector2i(-2, 0), "iron_ingot", 3)
		_check_victory()
		_check_long_night()
	factions_changed.emit()

# --- expeditions ------------------------------------------------------------

func expedition_active() -> bool:
	return not expedition.is_empty()

## A wild site's cooldown: 0 when ready, else ticks until worth returning.
func site_ready_in(id: String) -> int:
	return maxi(0, int(sites.get(id, 0)) - GameClock.ticks)

func send_expedition(target: String) -> void:
	if expedition_active():
		announced.emit("An expedition is already in the field.")
		return
	if SiteDefs.DEFS.has(target) and site_ready_in(target) > 0:
		announced.emit("The trail to %s is cold — give it a day or two." \
				% SiteDefs.get_def(target).name)
		return
	var party := _pick_party()
	if party.size() < 2:
		announced.emit("An expedition needs at least 2 armed, standing villagers.")
		return
	# Provisioning: pack spare food (power + fewer casualties) and a
	# bundle of herbs (fewer casualties). Supplies shift the odds.
	var food_packed := 0
	while food_packed < 3 and _consume_food(1):
		food_packed += 1
	var herb_packed := 1 if _consume("herb", 1) else 0
	var datas: Array = []
	var power := 0.0
	for pawn in party:
		power += _pawn_power(pawn)
		datas.append(_snapshot(pawn))
		main.remove_pawn_for_expedition(pawn)
	power += 3.0 * food_packed
	expedition = {
		"target": target,
		"return_tick": GameClock.ticks + EXPEDITION_TICKS,
		"party": datas,
		"power": power,
		"food": food_packed,
		"herb": herb_packed,
	}
	var packed := " Provisioned with %d food%s." % [food_packed, " and herbs" if herb_packed > 0 else ""] \
			if food_packed > 0 or herb_packed > 0 else ""
	announced.emit("The expedition marches out (%d strong).%s They return in a day." \
			% [datas.size(), packed])
	factions_changed.emit()

func _pawn_power(pawn: Pawn) -> float:
	var power := pawn.combat.attack_damage + 2.0 * pawn.skills.level("melee") \
			+ 2.0 * pawn.skills.level("archery") + pawn.combat.hp / 10.0 \
			+ pawn.combat.armor  # armor keeps them swinging longer
	if pawn.combat.relic_id != "":
		power += 15.0
	return power

## Plain-language risk estimate for the world map, before committing.
func expedition_odds(target: String) -> String:
	if not is_instance_valid(main):
		return ""
	var party := _pick_party()
	if party.size() < 2:
		return ""
	var power := 0.0
	for pawn in party:
		power += _pawn_power(pawn)
	var strength := float(SiteDefs.get_def(target).strength) if SiteDefs.DEFS.has(target) \
			else float(factions[target].strength)
	var p := power / (power + strength) + 0.1
	if p >= 0.75:
		return "The odds look strong."
	if p >= 0.5:
		return "An even fight."
	return "The odds look grim."

## Who would march if an expedition left now (world map preview).
func party_preview() -> String:
	if not is_instance_valid(main):
		return ""
	var names: Array[String] = []
	for pawn in _pick_party():
		names.append(String(pawn.name))
	return ", ".join(names)

func _pick_party() -> Array[Pawn]:
	var armed: Array[Pawn] = []
	for pawn: Pawn in main.pawns:
		if pawn.combat.weapon_id != "" and not pawn.collapsed and not pawn.dead:
			armed.append(pawn)
	armed.sort_custom(func(a: Pawn, b: Pawn) -> bool:
		return a.combat.attack_damage > b.combat.attack_damage)
	return armed.slice(0, 3)

func _snapshot(pawn: Pawn) -> Dictionary:
	return {
		"name": String(pawn.name),
		"hp": pawn.combat.hp,
		"weapon": pawn.combat.weapon_id,
		"armor": pawn.combat.armor_id,
		"ammo": pawn.combat.ammo,
		"relic": pawn.combat.relic_id,
		"skills": pawn.skills.xp.duplicate(),
		"traits": pawn.traits.duplicate(),
	}

func _resolve_expedition() -> void:
	var target: String = expedition.target
	var is_site := SiteDefs.DEFS.has(target)
	var strength := float(SiteDefs.get_def(target).strength) if is_site \
			else float(factions[target].strength)
	var power := float(expedition.power)
	var success := randf() < power / (power + strength) + 0.1  # luck favors the bold
	var report := ""
	var survivors: Array = []
	var casualties := 0
	# Provisions bring people home: food and herbs cut the casualty odds.
	var casualty_chance := (0.1 if success else 0.3) \
			- 0.03 * int(expedition.get("food", 0)) - 0.05 * int(expedition.get("herb", 0))
	casualty_chance = maxf(casualty_chance, 0.02)
	for pdata: Dictionary in expedition.party:
		if randf() < casualty_chance:
			casualties += 1
		else:
			survivors.append(pdata)
	if success:
		if is_site:
			_grant_site_loot(target)
			report = String(SiteDefs.get_def(target).report)
		else:
			report = "Victory! %s reels from the blow." % _fname(target)
	else:
		report = "The expedition was driven back from %s." \
				% (String(SiteDefs.get_def(target).name) if is_site else _fname(target))
	if casualties > 0:
		report += " %d did not come home." % casualties
	expedition = {}
	for pdata: Dictionary in survivors:
		main.return_expedition_member(pdata)
	for i in casualties:
		main.mourn_expedition_loss()
	if is_site:
		# Win or lose, the site needs time before it's worth returning.
		sites[target] = GameClock.ticks \
				+ int(SiteDefs.get_def(target).cooldown_days) * GameClock.TICKS_PER_DAY
	elif success:
		damage_strength(target, EXPEDITION_STRENGTH_HIT)
	announced.emit(report)
	factions_changed.emit()

## Site plunder: shards are the common treasure, full relics the rare one.
func _grant_site_loot(id: String) -> void:
	var def := SiteDefs.get_def(id)
	var center: Vector2i = WorldGrid.MAP_SIZE / 2
	if randf() < float(def.relic_chance):
		main.spawner.spawn_resource(center + Vector2i(0, 2), RelicDefs.ORDER.pick_random())
	for i in int(def.shards):
		main.spawner.drop_resource(center + Vector2i(i, 3), "relic_shard", 1)
	var offset := 0
	for res: String in def.resources:
		main.spawner.drop_resource(center + Vector2i(offset - 2, 0), res, int(def.resources[res]))
		offset += 2
	EventBus.chronicle_entry.emit(String(def.vignette))

# --- victory ----------------------------------------------------------------

func _check_victory() -> void:
	if victory_shown:
		return
	for id: String in factions:
		if factions[id].resolved == "":
			return
	victory_shown = true
	realm_ruled.emit()

## Act III trigger: the four other powers settled, the Legion alone unbroken.
## Fires once; the LongNightDirector takes it from there.
func _check_long_night() -> void:
	if long_night or not factions.has("ashen_legion"):
		return
	if factions["ashen_legion"].resolved != "":
		return  # the Legion was itself resolved — no siege (e.g. the Long Peace)
	for id: String in factions:
		if id != "ashen_legion" and factions[id].resolved == "":
			return
	long_night = true
	long_night_begins.emit()

## The siege is survived: the Legion breaks at the gates. → realm_ruled.
func break_the_legion() -> void:
	var f: Dictionary = factions["ashen_legion"]
	if f.resolved != "":
		return
	f.resolved = "destroyed"
	renown += 10
	announced.emit("The Ashen Legion breaks against your walls. The Long Night is over.")
	EventBus.chronicle_entry.emit("The Ashen Legion broke against Ashfall, and did not rise again.")
	factions_changed.emit()
	_check_victory()

# --- internals --------------------------------------------------------------

func _on_tick() -> void:
	if expedition_active() and GameClock.ticks >= int(expedition.return_tick) \
			and is_instance_valid(main):
		_resolve_expedition()
	for id: String in factions:
		var f: Dictionary = factions[id]
		if int(f.demand_deadline) > 0 and GameClock.ticks > int(f.demand_deadline):
			f.demand_deadline = 0
			announced.emit("%s's demand goes unanswered. They will remember." % _fname(id))
			_shift_attitude(id, -20.0)
	if not request.is_empty() and GameClock.ticks > int(request.deadline):
		announced.emit("%s's request lapses unanswered." % _fname(String(request.id)))
		_shift_attitude(String(request.id), -8.0)
		request = {}

func _on_day_started(_day: int) -> void:
	for id: String in factions:
		var f: Dictionary = factions[id]
		if f.resolved != "":
			continue
		if _personality(id) == "aggressive":
			_shift_attitude(id, -1.0)
		if float(f.attitude) < 0.0 and int(f.demand_deadline) == 0 \
				and randf() < DEMAND_CHANCE_PER_DAY:
			f.demand_deadline = GameClock.ticks + DEMAND_GRACE_TICKS
			announced.emit("%s demands tribute! Answer on the world map [M] within a day." % _fname(id))
			factions_changed.emit()
	if request.is_empty() and randf() < REQUEST_CHANCE_PER_DAY:
		_post_request()
	if randf() < WAR_CHANCE_PER_DAY:
		_skirmish()

## The realm moves on its own: two open factions trade blows and both
## bleed strength. Feed-only news — the chronicle is for the village.
func _skirmish() -> void:
	var open: Array[String] = []
	for id: String in factions:
		if factions[id].resolved == "":
			open.append(id)
	if open.size() < 2:
		return
	open.shuffle()
	var a: String = open[0]
	var b: String = open[1]
	var a_str := float(factions[a].strength)
	var b_str := float(factions[b].strength)
	var winner := a if randf() < a_str / maxf(a_str + b_str, 1.0) else b
	var loser := b if winner == a else a
	factions[loser].strength = maxf(float(factions[loser].strength) - 8.0, WAR_FLOOR)
	factions[winner].strength = maxf(float(factions[winner].strength) - 3.0, WAR_FLOOR)
	announced.emit("Word from the roads: %s raided %s. Both sides bled." \
			% [_fname(winner), _fname(loser)])
	factions_changed.emit()

## A faction asks for materials: meet it with a gift [M] before the
## deadline for outsized favor (+renown); let it lapse and they sour.
func _post_request() -> void:
	var open: Array[String] = []
	for id: String in factions:
		if factions[id].resolved == "":
			open.append(id)
	if open.is_empty():
		return
	var id: String = open.pick_random()
	request = {"id": id, "resource": ["wood", "stone"].pick_random(),
			"amount": randi_range(8, 14), "deadline": GameClock.ticks + REQUEST_GRACE_TICKS}
	announced.emit("%s asks for %d %s — send a gift [M] within two days and earn real favor." \
			% [_fname(id), int(request.amount), String(request.resource)])

func _shift_attitude(id: String, amount: float) -> void:
	var f: Dictionary = factions[id]
	f.attitude = clampf(float(f.attitude) + amount, -100.0, 100.0)
	if bool(f.get("oath", false)):
		f.attitude = maxf(float(f.attitude), 40.0)  # kinship holds a floor
	if float(f.attitude) >= ALLIANCE_AT and f.resolved == "":
		f.resolved = "allied"
		renown += 5
		announced.emit("%s pledges alliance! Their warriors will answer big raids." % _fname(id))
		EventBus.chronicle_entry.emit("%s of %s clasped hands with the village. An alliance is sworn." \
				% [_leader(id), _fname(id)])
		_check_victory()
		_check_long_night()
	factions_changed.emit()

func _resolved(id: String) -> bool:
	return factions[id].resolved != ""

func _personality(id: String) -> String:
	return FactionDefs.get_def(id).personality

func _fname(id: String) -> String:
	return FactionDefs.get_def(id).name

func _leader(id: String) -> String:
	return String(FactionDefs.get_def(id).get("leader", "their chief"))

func _count(id: String) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			total += 1
	return total

## Consume n free raw food items (expedition packs); false if short.
func _consume_food(n: int) -> bool:
	var found: Array[FoodItem] = []
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.kind == "raw" and not food.reserved:
			found.append(food)
			if found.size() >= n:
				break
	if found.size() < n:
		return false
	for food in found:
		food.queue_free()
	return true

func _consume(id: String, n: int) -> bool:
	var found: Array[ResourceItem] = []
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			found.append(item)
			if found.size() >= n:
				break
	if found.size() < n:
		return false
	for item in found:
		item.pick_up(self)
		item.queue_free()
	return true
