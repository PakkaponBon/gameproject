extends Node
## Autoload (Phase 6+): faction state, diplomacy, expeditions, victory.
## The world map is UI over this data — never a second simulated map.

signal factions_changed
signal announced(text: String)
signal realm_ruled

const GIFT_WOOD := 10
const LIKED_GIFT_BONUS := 25.0  # a leader's prized gift lands far harder
const TRIBUTE_WOOD := 15
const ENVOY_COOLDOWN_TICKS := 3000  # one envoy per faction per day
const DEMAND_CHANCE_PER_DAY := 0.2
const DEMAND_GRACE_TICKS := 3000  # a day to pay
const ALLIANCE_AT := 100.0
const REQUEST_CHANCE_PER_DAY := 0.25
const REQUEST_GRACE_TICKS := GameClock.TICKS_PER_DAY * 2
const EXPEDITION_TICKS := 3000  # the party is away one day
const EXPEDITION_STRENGTH_HIT := 25.0
const RUINS_STRENGTH := 50.0
const KILL_ATTRITION := 2.0  # faction strength lost per bandit slain

var factions := {}  # id -> {strength, attitude, resolved, envoy_ready, demand_deadline}
var expedition := {}  # {} when none; else target/return_tick/party/power
var request := {}  # {} or {id, resource, amount, deadline}: a faction's standing ask
var victory_shown := false
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
	victory_shown = false
	renown = 0
	factions_changed.emit()

func add_renown(amount: int) -> void:
	renown += amount
	factions_changed.emit()

func serialize() -> Dictionary:
	return {"factions": factions, "expedition": expedition, "request": request,
			"victory_shown": victory_shown, "renown": renown, "difficulty": Balance.mode}

func deserialize(data: Dictionary) -> void:
	factions = data.factions
	expedition = data.expedition
	request = data.get("request", {})
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
		if factions[id].resolved == "allied":
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
	factions_changed.emit()

# --- expeditions ------------------------------------------------------------

func expedition_active() -> bool:
	return not expedition.is_empty()

func send_expedition(target: String) -> void:
	if expedition_active():
		announced.emit("An expedition is already in the field.")
		return
	var party := _pick_party()
	if party.size() < 2:
		announced.emit("An expedition needs at least 2 armed, standing villagers.")
		return
	var datas: Array = []
	var power := 0.0
	for pawn in party:
		power += pawn.combat.attack_damage + 2.0 * pawn.skills.level("melee") \
				+ 2.0 * pawn.skills.level("archery") + pawn.combat.hp / 10.0
		if pawn.combat.relic_id != "":
			power += 15.0
		datas.append(_snapshot(pawn))
		main.remove_pawn_for_expedition(pawn)
	expedition = {
		"target": target,
		"return_tick": GameClock.ticks + EXPEDITION_TICKS,
		"party": datas,
		"power": power,
	}
	announced.emit("The expedition marches out (%d strong). They return in a day." % datas.size())
	factions_changed.emit()

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
	var strength := RUINS_STRENGTH if target == "ruins" else float(factions[target].strength)
	var power := float(expedition.power)
	var success := randf() < power / (power + strength) + 0.1  # luck favors the bold
	var report := ""
	var survivors: Array = []
	var casualties := 0
	for pdata: Dictionary in expedition.party:
		if randf() < (0.1 if success else 0.3):
			casualties += 1
		else:
			survivors.append(pdata)
	if success:
		if target == "ruins":
			var center: Vector2i = WorldGrid.MAP_SIZE / 2
			main.spawner.spawn_resource(center + Vector2i(0, 2), RelicDefs.ORDER.pick_random())
			main.spawner.drop_resource(center, "wood", 5)
			report = "The ruins gave up a relic!"
		else:
			report = "Victory! %s reels from the blow." % _fname(target)
	else:
		report = "The expedition was driven back from %s." \
				% ("the ruins" if target == "ruins" else _fname(target))
	if casualties > 0:
		report += " %d did not come home." % casualties
	expedition = {}
	for pdata: Dictionary in survivors:
		main.return_expedition_member(pdata)
	for i in casualties:
		main.mourn_expedition_loss()
	if success and target != "ruins":
		damage_strength(target, EXPEDITION_STRENGTH_HIT)
	announced.emit(report)
	factions_changed.emit()

# --- victory ----------------------------------------------------------------

func _check_victory() -> void:
	if victory_shown:
		return
	for id: String in factions:
		if factions[id].resolved == "":
			return
	victory_shown = true
	realm_ruled.emit()

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
	if float(f.attitude) >= ALLIANCE_AT and f.resolved == "":
		f.resolved = "allied"
		renown += 5
		announced.emit("%s pledges alliance! Their warriors will answer big raids." % _fname(id))
		EventBus.chronicle_entry.emit("%s of %s clasped hands with the village. An alliance is sworn." \
				% [_leader(id), _fname(id)])
		_check_victory()
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
