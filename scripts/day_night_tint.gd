extends CanvasModulate
## Rendering only: blends a per-season tint with the day/night cycle.
## HUD and menus live on CanvasLayers, so they stay untinted.

const SEASON_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0),     # spring
	Color(1.0, 0.98, 0.92),   # summer: warm
	Color(1.0, 0.93, 0.84),   # autumn: golden
	Color(0.85, 0.9, 1.0),    # winter: cold
]
const NIGHT_COLOR := Color(0.4, 0.45, 0.7)
const DAWN_COLOR := Color(1.05, 0.9, 0.7)  # gold morning light
const DUSK_COLOR := Color(1.0, 0.75, 0.55)  # orange evening

func _process(_delta: float) -> void:
	var season: Color = SEASON_TINTS[GameClock.season_index()]
	var f := GameClock.day_fraction()
	var tint: Color
	if f < 0.06:  # dawn gold fading into day
		tint = DAWN_COLOR.lerp(Color.WHITE, f / 0.06)
	elif f < 0.62:  # full day
		tint = Color.WHITE
	elif f < GameClock.NIGHT_START:  # dusk orange
		tint = Color.WHITE.lerp(DUSK_COLOR, (f - 0.62) / (GameClock.NIGHT_START - 0.62))
	elif f < GameClock.NIGHT_START + 0.05:  # dusk into night
		tint = DUSK_COLOR.lerp(NIGHT_COLOR, (f - GameClock.NIGHT_START) / 0.05)
	else:  # night blue
		tint = NIGHT_COLOR
	color = season * tint
