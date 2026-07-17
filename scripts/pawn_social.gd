class_name PawnSocial
extends Node
## Bonds between villagers: time spent close together — meals, breaks,
## festivals, standing a raid line — pulls pairs toward friendship;
## solitary souls drift apart instead. Pure drift math: the pawn brain
## never branches on bonds, only mood feels them.

const CHECK_EVERY := 25
const NEAR := 3
const DRIFT_PASSIVE := 0.15   # just being around each other
const DRIFT_TOGETHER := 0.6   # shared social moments bond faster
const DRIFT_SOLITARY := -0.4  # a loner in the pair sours proximity
const FRIEND_AT := 40.0
const RIVAL_AT := -40.0
const CAP := 100.0

var bonds := {}  # other pawn's name (String) -> score

var _check := 0

@onready var pawn: Pawn = get_parent()

func tick() -> void:
	_check -= 1
	if _check > 0:
		return
	_check = CHECK_EVERY
	var social_moment := pawn.needs.on_break or pawn.survival.food_target != null \
			or pawn.drafted or FestivalDirector.active_name != ""
	var friends_near := 0
	var rivals_near := 0
	for node in get_tree().get_nodes_in_group("pawns"):
		var other := node as Pawn
		if other == pawn or other.dead:
			continue
		var gap: Vector2i = other.cell - pawn.cell
		if absi(gap.x) > NEAR or absi(gap.y) > NEAR:
			continue
		var drift := DRIFT_TOGETHER if social_moment else DRIFT_PASSIVE
		if TraitDefs.has_flag(pawn.traits, "solitary") \
				or TraitDefs.has_flag(other.traits, "solitary"):
			drift = DRIFT_SOLITARY
		elif TraitDefs.has_flag(pawn.traits, "gregarious") \
				or TraitDefs.has_flag(other.traits, "gregarious"):
			drift *= 1.6  # a Warm soul in the pair bonds faster
		var key := String(other.name)
		var prev := float(bonds.get(key, 0.0))
		bonds[key] = clampf(prev + drift, -CAP, CAP)
		if prev < FRIEND_AT and float(bonds[key]) >= FRIEND_AT:
			Fx.emote(pawn, "<3", Color(0.95, 0.6, 0.7))
			if String(pawn.name) < key:  # one chronicle line per pair, not two
				EventBus.chronicle_entry.emit("%s and %s became fast friends." % [pawn.name, key])
		if is_friend(key):
			friends_near += 1
		elif is_rival(key):
			rivals_near += 1
	pawn.needs.social_tick(friends_near, rivals_near)

func is_friend(other_name: String) -> bool:
	return float(bonds.get(other_name, 0.0)) >= FRIEND_AT

func is_rival(other_name: String) -> bool:
	return float(bonds.get(other_name, 0.0)) <= RIVAL_AT

## "Friend of Fenna" / "Rival of Joss" for the villager card ("" if no
## bond has crossed a threshold yet).
func strongest_bond_text() -> String:
	var best_name := ""
	var best_abs := 0.0
	for key: String in bonds:
		if absf(float(bonds[key])) > best_abs:
			best_abs = absf(float(bonds[key]))
			best_name = key
	if best_name == "":
		return ""
	if is_friend(best_name):
		return "Friend of %s" % best_name
	if is_rival(best_name):
		return "Rival of %s" % best_name
	return ""
