class_name ResourceItem
extends Node2D
## A loose resource on the ground (wood, stone, ore — data-driven via
## ResourceDefs). Registers a haul job for itself whenever it sits outside
## a stockpile; stored items are inert.

var resource_id := "wood"  # set before add_child
var cell: Vector2i
var haul_job: Job = null
var equip_job: Job = null  # weapons only: claimable by weaponless villagers
var reserved := false  # claimed as blueprint material by a supplier pawn

var _home: Node = null  # container to return to after being carried

@onready var body: Sprite2D = $Body

func _ready() -> void:
	add_to_group("resources")
	var def := ResourceDefs.get_def(resource_id)
	body.region_rect = Rect2(int(def.sprite) * 16, 0, 16, 16)
	body.modulate = def.color
	_home = get_parent()
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	_settle()

func pick_up(carrier: Node) -> void:  # pawns carry; managers consume
	WorldGrid.unregister_item(cell)
	if haul_job:
		JobManager.remove_job(haul_job)
		haul_job = null
	if equip_job:
		JobManager.remove_job(equip_job)
		equip_job = null
	reparent(carrier)
	position = Vector2(0, -10)

func drop_at(drop_cell: Vector2i) -> void:
	reserved = false
	reparent(_home)
	cell = drop_cell
	position = WorldGrid.cell_to_world(cell)
	_settle()
	Fx.hop(self)

func _settle() -> void:
	# Check storage BEFORE registering, or our own presence marks the cell taken.
	var stored := WorldGrid.is_cell_free_for_storage(cell)
	WorldGrid.register_item(cell, self)
	if not stored:
		_register_haul_job()
	if WeaponDefs.DEFS.has(resource_id):
		_register_claim_job(Job.Type.EQUIP)
	elif ResourceDefs.get_def(resource_id).has("shots"):
		_register_claim_job(Job.Type.AMMO)
	elif ResourceDefs.get_def(resource_id).get("relic", false):
		_register_claim_job(Job.Type.RELIC)

func _register_haul_job() -> void:
	haul_job = Job.new()
	haul_job.type = Job.Type.HAUL
	haul_job.cell = cell
	haul_job.target = self
	JobManager.add_job(haul_job)

func _register_claim_job(type: Job.Type) -> void:
	equip_job = Job.new()
	equip_job.type = type
	equip_job.cell = cell
	equip_job.target = self
	JobManager.add_job(equip_job)
