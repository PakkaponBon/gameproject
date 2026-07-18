class_name TradePanel
extends CanvasLayer
## The traveling merchant's stall — a proper trading post. Wood is the
## currency (v0). Buy arms, armor, ammo, herbs, and the rare relic in stock;
## sell surplus stone, ore, ingots, wool, and hide. Code-built and data-
## driven (WARES / SELLABLES) so new goods are one line, no scene edits.

const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const RELIC_PRICE := 25

## Bought with wood. Grouped so the stall reads clearly.
const WARES := [
	{"id": "club", "price": 5}, {"id": "sword", "price": 8}, {"id": "spear", "price": 8},
	{"id": "warhammer", "price": 14}, {"id": "bow", "price": 12}, {"id": "arrow", "price": 3},
	{"id": "padded_coat", "price": 8}, {"id": "leather_jerkin", "price": 12}, {"id": "iron_mail", "price": 18},
	{"id": "herb", "price": 4},
]
## Sold for wood: n of id → gain wood.
const SELLABLES := [
	{"id": "stone", "count": 5, "gain": 3}, {"id": "iron_ore", "count": 2, "gain": 3},
	{"id": "iron_ingot", "count": 1, "gain": 4}, {"id": "wool", "count": 3, "gain": 3},
	{"id": "hide", "count": 3, "gain": 3},
]

var merchant: Merchant = null
var _stock_label: Label
var _relic_button: Button

func _ready() -> void:
	visible = false
	layer = 5
	_build_ui()
	EventBus.merchant_left.connect(close)

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_right = -12.0
	panel.offset_top = -220.0
	panel.offset_bottom = 220.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Label.new()
	title.text = "TRAVELING MERCHANT"
	title.theme_type_variation = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_stock_label = Label.new()
	_stock_label.theme_type_variation = "Muted"
	box.add_child(_stock_label)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(256, 320)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	_header(list, "BUY (wood)")
	_relic_button = Button.new()
	_relic_button.pressed.connect(_buy_relic)
	list.add_child(_relic_button)
	for ware: Dictionary in WARES:
		var id: String = ware.id
		var price: int = ware.price
		var btn := Button.new()
		btn.text = "%s — %d" % [ResourceDefs.get_def(id).name, price]
		btn.pressed.connect(func() -> void: _buy(id, price))
		list.add_child(btn)
	_header(list, "SELL (for wood)")
	for good: Dictionary in SELLABLES:
		var id: String = good.id
		var count: int = good.count
		var gain: int = good.gain
		var btn := Button.new()
		btn.text = "%d %s → %d wood" % [count, ResourceDefs.get_def(id).name, gain]
		btn.pressed.connect(func() -> void: _sell(id, count, gain))
		list.add_child(btn)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	box.add_child(close_btn)

func _header(list: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "Header"
	label.text = text
	list.add_child(label)

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
	_stock_label.text = "Wood %d · Stone %d · Ore %d · Ingots %d" \
			% [_count("wood"), _count("stone"), _count("iron_ore"), _count("iron_ingot")]
	if merchant.relic_in_stock != "":
		_relic_button.text = "%s — %d wood" % [ResourceDefs.get_def(merchant.relic_in_stock).name, RELIC_PRICE]
		_relic_button.disabled = false
	else:
		_relic_button.text = "Relic — sold"
		_relic_button.disabled = true

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
