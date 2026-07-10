class_name OreNode
extends Node2D
## A solid mineable rock (stone or iron ore, data-driven). Blocks all
## pathing; registers a MINE job worked from an adjacent cell; drops its
## resource and opens the cell when mined out.

const MINE_TICKS := 40  # 4s at 10 ticks/sec
const SPILL: Array[Vector2i] = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")

var resource_id := "stone"  # set before add_child
var cell: Vector2i
var job: Job

@onready var body: ColorRect = $Body
@onready var fleck: ColorRect = $Fleck

func _ready() -> void:
	add_to_group("ore_nodes")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	var def := ResourceDefs.get_def(resource_id)
	body.color = def.node_color
	fleck.color = def.color
	WorldGrid.set_obstacle(cell, true)
	job = Job.new()
	job.type = Job.Type.MINE
	job.cell = cell
	job.target = self
	job.work_ticks = MINE_TICKS
	job.completed.connect(_on_mined)
	JobManager.add_job(job)

## Save/load: restore remaining mining work.
func restore(work: int) -> void:
	job.work_ticks = work

func _on_mined() -> void:
	WorldGrid.set_obstacle(cell, false)
	var to_drop := int(ResourceDefs.get_def(resource_id).node_yield)
	var dropped := 0
	for offset in SPILL:
		if dropped >= to_drop:
			break
		var spot := cell + offset
		if WorldGrid.in_bounds(spot) and not WorldGrid.is_wall(spot) and not WorldGrid.items.has(spot):
			_spawn_item(spot)
			dropped += 1
	while dropped < to_drop:  # fallback: stack on the opened cell
		_spawn_item(cell)
		dropped += 1
	queue_free()

func _spawn_item(spot: Vector2i) -> void:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = resource_id
	item.position = WorldGrid.cell_to_world(spot)
	get_parent().add_child(item)
