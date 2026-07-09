extends CanvasModulate
## Rendering only: blends a per-season tint with the day/night cycle.
## HUD and menus live on CanvasLayers, so they stay untinted.

const SEASON_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),     # spring
	Color(1.0, 0.98, 0.92),   # summer: warm
	Color(1.0, 0.93, 0.84),   # autumn: golden
	Color(0.85, 0.9, 1.0),    # winter: cold
]
const NIGHT_COLOR := Color(0.45, 0.5, 0.72)
const RAMP := 0.05  # fraction of the day spent fading into/out of night

func _process(_delta: float) -> void:
	var season: Color = SEASON_TINTS[GameClock.season_index()]
	var f := GameClock.day_fraction()
	var night_amount := 0.0
	if f >= GameClock.NIGHT_START:
		night_amount = minf((f - GameClock.NIGHT_START) / RAMP, 1.0)
	elif f < RAMP:  # dawn: fade the night back out
		night_amount = 1.0 - f / RAMP
	color = season.lerp(NIGHT_COLOR * season, night_amount)
