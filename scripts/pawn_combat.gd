class_name PawnCombat
extends Node
## Melee combat for one pawn: health, armor, and fighting back at raiders.
## attack_damage/armor are variables on purpose — weapons, skills, and
## traits (later Phase 4 items) modify them.

signal damaged
signal defeated

const HP_MAX := 100.0
const ATTACK_COOLDOWN_TICKS := 10
const WOUNDED_BELOW := 0.5  # of max HP: slower work, seeks bed rest
const RECOVERED_AT := 0.9   # sleeps/heals until back to here
const HEAL_IN_BED := 0.08   # per tick while sleeping in a bed
const HEAL_ON_GROUND := 0.02

var hp := HP_MAX
var attack_damage := 5.0  # unarmed baseline
var armor := 0.0
var attack_cooldown := 0

@onready var pawn: Pawn = get_parent()

func tick() -> void:
	if attack_cooldown > 0:
		attack_cooldown -= 1

## Attacks an adjacent raider if there is one; returns true while engaged.
func engage_adjacent() -> bool:
	var raider := _adjacent_raider()
	if raider == null:
		return false
	if attack_cooldown <= 0:
		attack_cooldown = ATTACK_COOLDOWN_TICKS
		raider.take_damage(attack_damage)
	return true

func take_damage(amount: float) -> void:
	hp = maxf(hp - maxf(amount - armor, 1.0), 0.0)
	damaged.emit()
	if hp <= 0.0:
		defeated.emit()

## HP loss without the attacked reaction (starvation bleed-out etc.). No armor.
func drain(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	if hp <= 0.0:
		defeated.emit()

func heal(amount: float) -> void:
	hp = minf(hp + amount, HP_MAX)

func is_wounded() -> bool:
	return hp < HP_MAX * WOUNDED_BELOW

func fully_recovered() -> bool:
	return hp >= HP_MAX * RECOVERED_AT

func _adjacent_raider() -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		var d := (raider.cell - pawn.cell).abs()
		if d.x + d.y <= 1:
			return raider
	return null
