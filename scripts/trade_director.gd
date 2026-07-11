class_name TradeDirector
extends Node
## Rare traveling-merchant visits: each morning, a chance one wanders in
## (if none is already here). Scene-local to Main.

const MERCHANT_SCENE := preload("res://scenes/merchant.tscn")
const VISIT_CHANCE := 0.35

var spawn_parent: Node2D = null  # assigned by Main

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)

func _on_day_started(_day: int) -> void:
	if not get_tree().get_nodes_in_group("merchants").is_empty():
		return
	if randf() >= VISIT_CHANCE:
		return
	var edge := _random_edge_cell()
	var merchant: Merchant = MERCHANT_SCENE.instantiate()
	merchant.exit_cell = edge
	merchant.position = WorldGrid.cell_to_world(edge)
	spawn_parent.add_child(merchant)
	EventBus.merchant_arrived.emit()

func _random_edge_cell() -> Vector2i:
	var s := WorldGrid.MAP_SIZE
	for _attempt in 20:
		var cell := Vector2i(randi() % s.x, 0)
		match randi() % 4:
			1: cell = Vector2i(randi() % s.x, s.y - 1)
			2: cell = Vector2i(0, randi() % s.y)
			3: cell = Vector2i(s.x - 1, randi() % s.y)
		if not WorldGrid.is_wall(cell):
			return cell
	return Vector2i(s.x / 2, 0)
