class_name TradePanel
extends CanvasLayer
## Barter menu for a visiting merchant. Wood is the trade currency v0.
## Prices live in the constants below; goods move as real items.

const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const SWORD_PRICE := 8
const ARROW_PRICE := 3
const RELIC_PRICE := 25
const STONE_SELL_COUNT := 5
const STONE_SELL_GAIN := 3
const ORE_SELL_COUNT := 2
const ORE_SELL_GAIN := 3

var merchant: Merchant = null

func _ready() -> void:
	visible = false
	%BuySwordButton.pressed.connect(func() -> void: _buy("sword", SWORD_PRICE))
	%BuyArrowsButton.pressed.connect(func() -> void: _buy("arrow", ARROW_PRICE))
	%BuyRelicButton.pressed.connect(_buy_relic)
	%SellStoneButton.pressed.connect(func() -> void: _sell("stone", STONE_SELL_COUNT, STONE_SELL_GAIN))
	%SellOreButton.pressed.connect(func() -> void: _sell("iron_ore", ORE_SELL_COUNT, ORE_SELL_GAIN))
	%CloseTradeButton.pressed.connect(close)
	EventBus.merchant_left.connect(close)

func open(with_merchant: Merchant) -> void:
	merchant = with_merchant
	visible = true
	_refresh()

func close() -> void:
	visible = false
	merchant = null

func _refresh() -> void:
	if not is_instance_valid(merchant):
		close()
		return
	%TradeStockLabel.text = "Colony wood: %d   stone: %d   ore: %d" \
			% [_count("wood"), _count("stone"), _count("iron_ore")]
	if merchant.relic_in_stock != "":
		%BuyRelicButton.text = "Buy %s — %d wood" \
				% [ResourceDefs.get_def(merchant.relic_in_stock).name, RELIC_PRICE]
		%BuyRelicButton.disabled = false
	else:
		%BuyRelicButton.text = "Relic — SOLD"
		%BuyRelicButton.disabled = true

func _buy(id: String, price: int) -> void:
	if not is_instance_valid(merchant):
		close()
		return
	if _consume("wood", price):
		_spawn(id)
	_refresh()

func _buy_relic() -> void:
	if not is_instance_valid(merchant) or merchant.relic_in_stock == "":
		return
	if _consume("wood", RELIC_PRICE):
		_spawn(merchant.relic_in_stock)
		merchant.relic_in_stock = ""
	_refresh()

func _sell(id: String, count: int, wood_gain: int) -> void:
	if not is_instance_valid(merchant):
		close()
		return
	if _consume(id, count):
		for i in wood_gain:
			_spawn("wood")
	_refresh()

func _count(id: String) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			total += 1
	return total

## Remove n free items of a kind from the world. False if too few exist.
func _consume(id: String, n: int) -> bool:
	var found: Array[ResourceItem] = []
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.resource_id == id and not item.reserved and not (item.get_parent() is Pawn):
			found.append(item)
			if found.size() >= n:
				break
	if found.size() < n:
		return false
	for item in found:
		item.pick_up(merchant)  # clears jobs and cell registration
		item.queue_free()
	return true

func _spawn(id: String) -> void:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = id
	item.position = WorldGrid.cell_to_world(merchant.cell)
	merchant.get_parent().add_child(item)
