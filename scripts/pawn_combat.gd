class_name PawnCombat
extends Node
## Melee combat for one pawn: health, fighting back at adjacent raiders.

signal damaged
signal defeated

const HP_MAX := 100.0
const ATTACK_DAMAGE := 10.0
const ATTACK_COOLDOWN_TICKS := 10

var hp := HP_MAX
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
		raider.take_damage(ATTACK_DAMAGE)
	return true

func take_damage(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	damaged.emit()
	if hp <= 0.0:
		defeated.emit()

func _adjacent_raider() -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		var d := (raider.cell - pawn.cell).abs()
		if d.x + d.y <= 1:
			return raider
	return null
