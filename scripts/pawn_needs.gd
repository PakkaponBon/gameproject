class_name PawnNeeds
extends Node
## Hunger and mood for one pawn. Pure stats and thresholds — the pawn
## decides how to act on the signals.

signal starved
signal changed
signal break_started
signal break_ended

const HUNGER_MAX := 100.0
const HUNGER_DRAIN_PER_TICK := 0.1  # empty in ~100s at 10 ticks/sec
const HUNGRY_AT := 35.0

const MOOD_MAX := 100.0
const MOOD_RECOVERY_PER_TICK := 0.03
const MOOD_HUNGRY_DRAIN_PER_TICK := 0.08
const MOOD_HIT_WHEN_ATTACKED := 10.0
const BREAK_AT := 20.0
const BREAK_OVER_AT := 50.0

var hunger := HUNGER_MAX
var mood := MOOD_MAX
var on_break := false

func tick() -> void:
	hunger = maxf(hunger - HUNGER_DRAIN_PER_TICK, 0.0)
	if is_hungry():
		mood = maxf(mood - MOOD_HUNGRY_DRAIN_PER_TICK, 0.0)
	else:
		mood = minf(mood + MOOD_RECOVERY_PER_TICK, MOOD_MAX)
	if on_break and mood >= BREAK_OVER_AT:
		on_break = false
		break_ended.emit()
	elif not on_break and mood <= BREAK_AT:
		on_break = true
		break_started.emit()
	changed.emit()
	if hunger <= 0.0:
		starved.emit()

func is_hungry() -> bool:
	return hunger < HUNGRY_AT

func eat() -> void:
	hunger = HUNGER_MAX
	mood = minf(mood + 5.0, MOOD_MAX)
	changed.emit()

func attacked() -> void:
	mood = maxf(mood - MOOD_HIT_WHEN_ATTACKED, 0.0)
	changed.emit()
