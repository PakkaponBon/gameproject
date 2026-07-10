class_name PawnNeeds
extends Node
## Hunger, rest, and mood for one pawn. Pure stats and thresholds — the
## pawn decides how to act on the signals.

signal starved
signal changed
signal break_started
signal break_ended

const HUNGER_MAX := 100.0
const HUNGER_DRAIN_PER_TICK := 0.1  # empty in ~100s at 10 ticks/sec
const HUNGRY_AT := 35.0

const REST_MAX := 100.0
const REST_DRAIN_PER_TICK := 0.04  # empty in ~0.83 in-game days
const REST_RESTORE_BED := 0.18     # a full night in a bed ≈ full bar
const REST_RESTORE_GROUND := 0.08
const TIRED_AT := 35.0
const NIGHT_SLEEPY_AT := 70.0  # at night, sleep unless mostly rested
const EXHAUSTED_AT := 15.0
const RESTED_AT := 95.0

const MOOD_MAX := 100.0
const MOOD_RECOVERY_PER_TICK := 0.03
const MOOD_HUNGRY_DRAIN_PER_TICK := 0.08
const MOOD_EXHAUSTED_DRAIN_PER_TICK := 0.05
const MOOD_HIT_WHEN_ATTACKED := 10.0
const BREAK_AT := 20.0
const BREAK_OVER_AT := 50.0
## Below this mood, work slows linearly down to MOOD_MIN_WORK_FACTOR at 0.
const MOOD_SLOW_BELOW := 60.0
const MOOD_MIN_WORK_FACTOR := 0.6

var hunger := HUNGER_MAX
var rest := REST_MAX
var mood := MOOD_MAX
var on_break := false

func tick(sleeping := false, in_bed := false) -> void:
	hunger = maxf(hunger - HUNGER_DRAIN_PER_TICK, 0.0)
	if sleeping:
		rest = minf(rest + (REST_RESTORE_BED if in_bed else REST_RESTORE_GROUND), REST_MAX)
	else:
		rest = maxf(rest - REST_DRAIN_PER_TICK, 0.0)
	if is_hungry() or is_exhausted():
		var drain := 0.0
		if is_hungry():
			drain += MOOD_HUNGRY_DRAIN_PER_TICK
		if is_exhausted():
			drain += MOOD_EXHAUSTED_DRAIN_PER_TICK
		mood = maxf(mood - drain, 0.0)
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

func wants_sleep() -> bool:
	return rest < TIRED_AT or (GameClock.is_night() and rest < NIGHT_SLEEPY_AT)

func is_exhausted() -> bool:
	return rest < EXHAUSTED_AT

func is_rested() -> bool:
	return rest >= RESTED_AT

## 1.0 at good mood, sliding to MOOD_MIN_WORK_FACTOR at rock bottom.
## Foundation for trait/death modifiers later (they multiply in here).
func mood_work_factor() -> float:
	if mood >= MOOD_SLOW_BELOW:
		return 1.0
	return lerpf(MOOD_MIN_WORK_FACTOR, 1.0, mood / MOOD_SLOW_BELOW)

func eat() -> void:
	hunger = HUNGER_MAX
	mood = minf(mood + 5.0, MOOD_MAX)
	changed.emit()

func attacked() -> void:
	mood = maxf(mood - MOOD_HIT_WHEN_ATTACKED, 0.0)
	changed.emit()
