class_name Pawn
extends Node2D
## Movement, tick orchestration, and player-facing state for one villager.
## Behaviors live in components: PawnNeeds (stats), PawnSurvival (food,
## sleep, wandering), PawnWork (colony jobs), PawnCombat (melee, draft,
## raid response).

signal stats_changed
signal died

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const BODY_COLOR := Color.WHITE  # real character art now; tints only for states
const SLEEP_COLOR := Color(0.55, 0.6, 0.8)
const COLLAPSE_COLOR := Color(0.75, 0.78, 0.95)
const COLLAPSE_HP_DRAIN := 0.2  # per tick: ~50s from full HP to death

var cell: Vector2i
var target_cell: Vector2i
var collapsed := false  # starved: prone, helpless, bleeding out
var feed_job: Job = null
var treat_job: Job = null  # wounded: a helper can bring herbs
var drafted := false  # player-controlled: no jobs, no auto needs-seeking
var dead := false
var _selected := false

## 1 = preferred, higher = later, 0 = never does this job type.
var work_priorities := {Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1}
var traits: Array = []  # trait ids from TraitDefs

@onready var body: Sprite2D = $Body
@onready var held: Sprite2D = $Held
@onready var selection_ring: ColorRect = $SelectionRing
@onready var needs: PawnNeeds = $Needs
@onready var combat: PawnCombat = $Combat
@onready var work: PawnWork = $Work
@onready var survival: PawnSurvival = $Survival
@onready var skills: PawnSkills = $Skills
@onready var social: PawnSocial = $Social

func _ready() -> void:
	add_to_group("pawns")
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	needs.starved.connect(_collapse)
	needs.changed.connect(stats_changed.emit)
	needs.break_started.connect(_on_break_started)
	combat.damaged.connect(_on_damaged)
	combat.defeated.connect(_die)
	GameClock.ticked.connect(_on_tick)

func set_selected(on: bool) -> void:
	_selected = on
	_update_ring()

func set_drafted(on: bool) -> void:
	if dead or collapsed:
		return
	drafted = on
	combat.attack_target = null
	if on:
		survival.wake()
		abort_all()
		target_cell = cell
	_update_ring()

## Draft order: pursue and engage a raider.
func attack(raider: Raider) -> void:
	if drafted:
		combat.attack_target = raider

## Show the equipped weapon in hand.
func update_held() -> void:
	held.visible = combat.weapon_id != ""
	if held.visible:
		var idx := int(ResourceDefs.get_def(combat.weapon_id).sprite)
		held.region_rect = Rect2(idx * 16, 0, 16, 16)

func set_sleep_visual(on: bool) -> void:
	if not dead:
		body.modulate = SLEEP_COLOR if on else BODY_COLOR

func cycle_priority(type: Job.Type) -> void:
	# 1 -> 2 -> 3 -> 0 (off) -> 1
	work_priorities[type] = (int(work_priorities[type]) + 1) % 4

## Player command: overrides current work; carried items drop on the spot.
func move_to(destination: Vector2i) -> void:
	if dead or collapsed or not WorldGrid.in_bounds(destination):
		return
	combat.attack_target = null
	survival.wake()
	abort_all()
	target_cell = destination

func take_damage(amount: float) -> void:
	if not dead:
		Fx.flash(body)
		Fx.damage_number(self, amount)
		combat.take_damage(amount)

## Fed by a rescuer: back on your feet, hungry but alive.
func be_fed() -> void:
	collapsed = false
	feed_job = null
	needs.hunger = 50.0
	body.rotation_degrees = 0.0
	body.modulate = BODY_COLOR
	stats_changed.emit()

## Human-readable "what am I doing" for the villager panel.
func activity_text() -> String:
	if dead:
		return "Dead"
	if collapsed:
		return "Collapsed — starving!"
	if drafted:
		return "Drafted — awaiting orders" if combat.attack_target == null else "Drafted — attacking"
	if survival.sleeping:
		return "Sleeping"
	if survival.food_target:
		return "Getting food"
	if needs.on_break:
		return "Mental break"
	if work.carrying_food:
		return "Rescuing with food"
	if work.carrying_herb:
		return "Treating a wound"
	if work.carrying:
		return "Hauling %s" % ResourceDefs.get_def(work.carrying.resource_id).name
	if work.job:
		return (Job.Type.keys()[work.job.type] as String).capitalize()
	return "Idle"

## Leaving on expedition: release every claim cleanly before removal.
func prepare_depart() -> void:
	survival.wake()
	clear_treat_job()
	abort_all()
	drafted = false
	combat.attack_target = null

## Save/load: restore a collapsed pawn (re-registers its FEED job).
func restore_collapse() -> void:
	collapsed = true
	_apply_collapse_visuals()
	_register_feed_job()

func step() -> void:
	_step()

func abort_all(clear_food := true) -> void:
	work.abort()
	survival.release_claims(clear_food)

func _on_tick() -> void:
	if dead:
		return
	needs.tick(survival.sleeping, survival.is_in_bed(), WorldGrid.is_indoors(cell),
			WorldGrid.is_warm_spot(cell), WorldGrid.comfort_at(cell))
	if dead:
		return
	social.tick()
	if collapsed:
		combat.drain(COLLAPSE_HP_DRAIN)  # defeated -> _die
		return
	combat.tick()
	combat.relic_tick()
	_update_treat_job()
	# Archers shoot from range; melee is survival when enemies close in.
	if combat.ranged_tick():
		survival.wake()
		return
	if combat.engage_adjacent():
		survival.wake()
		return
	if drafted:
		combat.drafted_tick()
		return
	if survival.sleeping:
		combat.heal(PawnCombat.HEAL_IN_BED if survival.is_in_bed() else PawnCombat.HEAL_ON_GROUND)
		if needs.is_hungry() or (needs.is_rested() and combat.fully_recovered()):
			survival.wake()
		return
	survival.seek_food()
	combat.flee_if_raid()
	survival.seek_bed()
	if cell != target_cell:
		_step()
	elif survival.food_target:
		survival.eat_tick()
	elif survival.at_bed():
		survival.fall_asleep()
	elif needs.wants_sleep() and needs.is_exhausted():
		survival.fall_asleep()  # no bed available: collapse where we stand
	elif needs.on_break:
		survival.seek_comfort_or_wander()
	elif combat.sheltering():
		pass  # wait out the raid inside the safety zone
	elif _festival_evening():
		survival.seek_comfort_or_wander()  # gather at the warm heart of home
	elif work.busy():
		work.on_arrived()
	else:
		work.request_next()

## Festival evenings pull idle villagers toward the nicest spot in the
## village instead of new work.
func _festival_evening() -> bool:
	return FestivalDirector.active_name != "" \
			and GameClock.day_fraction() > 0.6 and GameClock.day_fraction() < 0.85

func _step() -> void:
	# Repath every tick so walls placed mid-walk are respected immediately.
	# allow_partial_path lets a click on a wall walk to the closest reachable cell.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target_cell, true)
	if path.size() < 2:
		# Destination unreachable; give up. Job/food searches filter
		# unreachable targets, so abandoned work won't be re-taken.
		target_cell = cell
		abort_all()
		return
	cell = path[1]
	if (cell.x + cell.y) % 2 == 0:
		EventBus.play_sfx.emit("step")  # SoundManager throttles the patter

func _on_damaged() -> void:
	if survival.sleeping:
		survival.wake()
	EventBus.play_sfx.emit("hurt")
	needs.attacked()
	stats_changed.emit()

func _on_break_started() -> void:
	# Mental break: drop colony work, but keep heading to food if hungry.
	Fx.emote(self, "!", Color(0.9, 0.35, 0.3))
	work.abort()
	if survival.food_target == null:
		target_cell = cell

func _update_ring() -> void:
	# The ring doubles as the draft marker: red while drafted, white while
	# merely selected.
	selection_ring.visible = _selected or drafted
	selection_ring.color = Color(0.9, 0.25, 0.2, 0.5) if drafted else Color(1, 1, 1, 0.35)

func _collapse() -> void:
	if collapsed or dead:
		return
	drafted = false
	combat.attack_target = null
	_update_ring()
	survival.wake()
	abort_all()
	collapsed = true
	target_cell = cell
	_apply_collapse_visuals()
	_register_feed_job()
	stats_changed.emit()

## Herb treatment: a wounded villager invites help; healed = job gone.
func _update_treat_job() -> void:
	if combat.is_wounded() and treat_job == null:
		treat_job = Job.new()
		treat_job.type = Job.Type.TREAT
		treat_job.cell = cell
		treat_job.target = self
		JobManager.add_job(treat_job)
	elif treat_job and not combat.is_wounded():
		JobManager.remove_job(treat_job)
		treat_job = null

func clear_treat_job() -> void:
	if treat_job:
		JobManager.remove_job(treat_job)
		treat_job = null

func _register_feed_job() -> void:
	feed_job = Job.new()
	feed_job.type = Job.Type.FEED
	feed_job.cell = cell
	feed_job.target = self
	feed_job.completed.connect(be_fed)
	JobManager.add_job(feed_job)

func _apply_collapse_visuals() -> void:
	body.modulate = COLLAPSE_COLOR
	body.rotation_degrees = 90.0  # Sprite2D rotates around its center

## Death: release everything, tell the colony, and fade — Main replaces
## us with a grave (no lingering corpse; tone rule).
func _die() -> void:
	dead = true
	collapsed = false
	if feed_job:
		JobManager.remove_job(feed_job)
		feed_job = null
	clear_treat_job()
	abort_all()
	EventBus.play_sfx.emit("death")
	died.emit()
	queue_free()

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell,
	# and alternate walk frames while moving.
	var dest := WorldGrid.cell_to_world(cell)
	position = position.lerp(dest, minf(1.0, LERP_WEIGHT * delta))
	if not dead and not collapsed:
		var walking := position.distance_to(dest) > 1.5 or cell != target_cell
		var frame := 14 if walking and int(Time.get_ticks_msec() / 180) % 2 == 0 else 0
		body.region_rect.position.x = frame * 16
		if absf(dest.x - position.x) > 0.5:
			body.flip_h = dest.x < position.x  # face where we're headed
