extends Node
## Autoload: fixed simulation tick, decoupled from render framerate, plus
## the calendar derived from it (days, seasons, day/night). Only `ticks`
## needs saving — everything else is computed.

signal ticked
signal day_started(day: int)
signal season_changed(season: int)
signal speed_changed  # sim pause or speed multiplier flipped

const TICKS_PER_SECOND := 10.0
const TICKS_PER_DAY := 3000  # 5 real minutes per in-game day
const DAYS_PER_SEASON := 5
const SEASON_NAMES := ["Spring", "Summer", "Autumn", "Winter"]
const NIGHT_START := 0.75  # last quarter of each day is night

var ticks := 0  # total simulation ticks; persisted in saves
var sim_paused := false  # tactical pause: sim frozen, player still plans
var speed := 1.0

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 1.0 / TICKS_PER_SECOND
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func set_sim_paused(on: bool) -> void:
	sim_paused = on
	_timer.paused = on
	speed_changed.emit()

func set_speed(mult: float) -> void:
	speed = mult
	_timer.wait_time = 1.0 / (TICKS_PER_SECOND * mult)
	speed_changed.emit()

func _on_timeout() -> void:
	ticks += 1
	ticked.emit()
	if ticks % TICKS_PER_DAY == 0:
		day_started.emit(total_days())
		if total_days() % DAYS_PER_SEASON == 0:
			season_changed.emit(season_index())

func total_days() -> int:
	return ticks / TICKS_PER_DAY

## 0.0 = dawn, 1.0 = end of night.
func day_fraction() -> float:
	return float(ticks % TICKS_PER_DAY) / float(TICKS_PER_DAY)

func is_night() -> bool:
	return day_fraction() >= NIGHT_START

func season_index() -> int:
	return (total_days() / DAYS_PER_SEASON) % SEASON_NAMES.size()

func season_name() -> String:
	return SEASON_NAMES[season_index()]

func day_of_season() -> int:
	return total_days() % DAYS_PER_SEASON + 1

func year() -> int:
	return total_days() / (DAYS_PER_SEASON * SEASON_NAMES.size()) + 1

func calendar_text() -> String:
	var f := day_fraction()
	var phase := "Night"
	if f < 0.25:
		phase = "Morning"
	elif f < 0.5:
		phase = "Midday"
	elif f < NIGHT_START:
		phase = "Evening"
	return "Year %d — %s, Day %d/%d — %s" % [year(), season_name(), day_of_season(), DAYS_PER_SEASON, phase]
