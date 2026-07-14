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

const WARMTH_MAX := 100.0
const WARMTH_DRAIN_WINTER := 0.06   # outdoors in winter: chilled in ~3 min
const WARMTH_REGAIN_INDOORS := 0.08
const WARMTH_REGAIN_FIRE := 0.4
const COLD_AT := 30.0
const MOOD_COLD_DRAIN_PER_TICK := 0.06
const COLD_WORK_FACTOR := 0.8  # numb fingers — cold never kills, it slows

const JOY_MAX := 100.0
const JOY_DRAIN_PER_TICK := 0.004  # life dulls over ~4 days of nothing but work
const JOY_REGAIN_COMFORT := 0.03   # per comfort point while somewhere nice
const JOYLESS_AT := 25.0
const MOOD_JOYLESS_DRAIN_PER_TICK := 0.03

const MOOD_MAX := 100.0
const MOOD_RECOVERY_PER_TICK := 0.03
const MOOD_HUNGRY_DRAIN_PER_TICK := 0.08
const MOOD_EXHAUSTED_DRAIN_PER_TICK := 0.05
const MOOD_HIT_WHEN_ATTACKED := 10.0
const MOOD_HIT_DEATH := 20.0  # a fellow villager died
const MOOD_HIT_GRIEF := 35.0  # ...who was a friend
const BREAK_AT := 20.0
const BREAK_OVER_AT := 50.0
## Below this mood, work slows linearly down to MOOD_MIN_WORK_FACTOR at 0.
const MOOD_SLOW_BELOW := 60.0
const MOOD_MIN_WORK_FACTOR := 0.6

var hunger := HUNGER_MAX
var rest := REST_MAX
var mood := MOOD_MAX
var warmth := WARMTH_MAX
var joy := 70.0
var on_break := false

func tick(sleeping := false, in_bed := false, indoors := false,
		near_fire := false, comfort := 0.0) -> void:
	hunger = maxf(hunger - HUNGER_DRAIN_PER_TICK, 0.0)
	if sleeping:
		rest = minf(rest + (REST_RESTORE_BED if in_bed else REST_RESTORE_GROUND), REST_MAX)
	else:
		rest = maxf(rest - REST_DRAIN_PER_TICK, 0.0)
	# Warmth: winter bites outdoors; walls and fire push it back.
	if near_fire:
		warmth = minf(warmth + WARMTH_REGAIN_FIRE, WARMTH_MAX)
	elif indoors or GameClock.season_index() != 3:
		warmth = minf(warmth + WARMTH_REGAIN_INDOORS, WARMTH_MAX)
	else:
		warmth = maxf(warmth - WARMTH_DRAIN_WINTER, 0.0)
	# Joy: slow dulling; nice spots (furniture, hearthside) restore it.
	if comfort > 0.0:
		joy = minf(joy + JOY_REGAIN_COMFORT * comfort, JOY_MAX)
	else:
		joy = maxf(joy - JOY_DRAIN_PER_TICK, 0.0)
	var drain := 0.0
	if is_hungry():
		drain += MOOD_HUNGRY_DRAIN_PER_TICK
	if is_exhausted():
		drain += MOOD_EXHAUSTED_DRAIN_PER_TICK
	if is_cold():
		drain += MOOD_COLD_DRAIN_PER_TICK
	if is_joyless():
		drain += MOOD_JOYLESS_DRAIN_PER_TICK
	if drain > 0.0:
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

func is_cold() -> bool:
	return warmth < COLD_AT

func is_joyless() -> bool:
	return joy < JOYLESS_AT

## 1.0 at good mood, sliding to MOOD_MIN_WORK_FACTOR at rock bottom.
## Cold multiplies in on top: numb fingers work slower.
func mood_work_factor() -> float:
	var factor := 1.0
	if mood < MOOD_SLOW_BELOW:
		factor = lerpf(MOOD_MIN_WORK_FACTOR, 1.0, mood / MOOD_SLOW_BELOW)
	return factor * (COLD_WORK_FACTOR if is_cold() else 1.0)

## Meals fill completely and lift spirits; raw food just staves it off.
func eat(meal := false) -> void:
	if meal:
		hunger = HUNGER_MAX
		mood = minf(mood + 12.0, MOOD_MAX)
	else:
		hunger = minf(hunger + 65.0, HUNGER_MAX)
		mood = minf(mood + 3.0, MOOD_MAX)
	changed.emit()

func attacked() -> void:
	mood = maxf(mood - MOOD_HIT_WHEN_ATTACKED, 0.0)
	changed.emit()

func mourn() -> void:
	mood = maxf(mood - MOOD_HIT_DEATH, 0.0)
	changed.emit()

## The dead villager was a friend: it cuts deeper.
func grieve() -> void:
	mood = maxf(mood - MOOD_HIT_GRIEF, 0.0)
	changed.emit()

## Festival day: spirits lift, the grind is forgiven for a while.
func celebrate() -> void:
	joy = maxf(joy, 90.0)
	mood = minf(mood + 15.0, MOOD_MAX)
	changed.emit()

## Social ripple from PawnSocial (per its check interval, not per tick).
func social_tick(friends_near: int, rivals_near: int) -> void:
	if friends_near == 0 and rivals_near == 0:
		return
	mood = clampf(mood + friends_near * 0.2 - rivals_near * 0.3, 0.0, MOOD_MAX)
