class_name WeatherDirector
extends Node
## A light weather layer: one roll per morning. Rain speeds crops and dims
## the mood a little; storms also slow outdoor work; snow is a winter
## visual. No fire, no fluid sim (permanent non-goals) — just data + a
## screen-space particle overlay. Static `current` lets crops and work
## read the weather without holding a reference (like FestivalDirector).

const MOOD_EVERY_TICKS := 40

static var current := "clear"  # "clear" | "rain" | "storm" | "snow"

var _overlay: CanvasLayer
var _particles: CPUParticles2D
var _mood_cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	current = "clear"  # statics outlive scene reloads; each world starts clear
	_build_overlay()
	GameClock.day_started.connect(_on_day_started)
	GameClock.ticked.connect(_on_tick)
	_apply_visual()

# --- static reads used by crops and work ------------------------------------

## Extra chance per tick to advance a crop (wet weather speeds growth).
static func growth_extra_chance() -> float:
	match current:
		"rain": return 0.5
		"storm": return 0.35
	return 0.0

## Outdoor work multiplier — a storm makes hauling and building a slog.
static func outdoor_work_mult() -> float:
	return 0.75 if current == "storm" else 1.0

# --- rolling ----------------------------------------------------------------

func _on_day_started(_day: int) -> void:
	var was := current
	if GameClock.season_index() == 3:  # winter: snow or clear cold
		current = "snow" if randf() < 0.5 else "clear"
	else:
		var r := randf()
		current = "storm" if r < 0.12 else ("rain" if r < 0.4 else "clear")
	if current != was:
		_announce()
	_apply_visual()

## Save/load: restore the day's weather and its visual.
func set_weather(weather: String) -> void:
	current = weather
	_apply_visual()

func _announce() -> void:
	var line: String = {
		"rain": "Rain sweeps in over the meadow.",
		"storm": "A storm rolls in — work drags in the wet and wind.",
		"snow": "Snow settles quietly over the village.",
		"clear": "The sky clears.",
	}.get(current, "")
	if line != "":
		main.hud.set_event(line, Color(0.7, 0.8, 0.95))

# --- effects ----------------------------------------------------------------

func _on_tick() -> void:
	if current != "rain" and current != "storm":
		return
	_mood_cooldown -= 1
	if _mood_cooldown > 0:
		return
	_mood_cooldown = MOOD_EVERY_TICKS
	var dip := 0.6 if current == "storm" else 0.3
	for pawn: Pawn in main.pawns:
		if not pawn.dead and not pawn.survival.sleeping and not WorldGrid.is_indoors(pawn.cell):
			pawn.needs.mood = maxf(pawn.needs.mood - dip, 0.0)

# --- visuals ----------------------------------------------------------------

func _build_overlay() -> void:
	# Screen-space overlay above the world (particles fall in front of the
	# view). Sits over the HUD too, but they're light translucent dots.
	_overlay = CanvasLayer.new()
	_overlay.layer = 2
	add_child(_overlay)
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(700, 2)
	_particles.position = Vector2(576, -12)  # top-center of a 1152-wide view
	_particles.local_coords = false
	_overlay.add_child(_particles)

func _apply_visual() -> void:
	match current:
		"rain":
			_configure_rain(220, 3.0, Color(0.6, 0.72, 0.95, 0.55))
		"storm":
			_configure_rain(420, 4.5, Color(0.55, 0.65, 0.9, 0.65))
		"snow":
			_configure_snow()
		_:
			_particles.emitting = false

func _configure_rain(amount: int, length: float, tint: Color) -> void:
	_particles.amount = amount
	_particles.lifetime = 1.0
	_particles.direction = Vector2(0.15, 1.0)
	_particles.spread = 4.0
	_particles.gravity = Vector2(0, 600)
	_particles.initial_velocity_min = 380.0
	_particles.initial_velocity_max = 520.0
	_particles.scale_amount_min = length
	_particles.scale_amount_max = length
	_particles.color = tint
	_particles.emitting = true

func _configure_snow() -> void:
	_particles.amount = 160
	_particles.lifetime = 4.0
	_particles.direction = Vector2(0.2, 1.0)
	_particles.spread = 25.0
	_particles.gravity = Vector2(0, 40)
	_particles.initial_velocity_min = 20.0
	_particles.initial_velocity_max = 45.0
	_particles.scale_amount_min = 2.0
	_particles.scale_amount_max = 3.0
	_particles.color = Color(0.95, 0.97, 1.0, 0.85)
	_particles.emitting = true
